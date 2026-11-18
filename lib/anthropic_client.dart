import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_providers.dart';
import 'api_key_store.dart';
import 'quota_guard.dart';
import 'zero_cost_policy.dart';

/// (File name kept for compatibility — this is the app's single AI gateway /
/// provider manager. Every AI feature calls it.)
///
/// ZERO-COST-FIRST:
///  1. Free providers in priority order (default Groq, Cerebras, Gemini,
///     OpenRouter free models). Each model must pass ZeroCostPolicy.
///  2. Optional paid Anthropic is ALWAYS last and stays blocked while
///     "zero-cost-only" mode is ON (the default).
///  3. If everything is unavailable the call returns an offline-mode
///     message (starts with "(") — the Offline Academy keeps working.
/// Conversation continuity: the full history is sent to whichever
/// provider answers, so switching providers mid-chat is seamless.

class PrefsQuotaStorage implements QuotaStorage {
  static const _key = 'quota_guard_v1';
  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(_key);
  @override
  Future<void> write(String data) async => (await SharedPreferences.getInstance()).setString(_key, data);
}

enum ProviderState { notConfigured, ready, rateLimited, blockedPaid, noVerifiedModel, keyRejected, disabledByUser }

class ProviderStatus {
  final AiProvider provider;
  final bool hasKey;
  final bool enabled;
  final ProviderState state;
  final String detail;
  final String? activeModel;
  final int usedToday;
  final int usedLastMinute;
  final int? guardRpm;
  final int? guardRpd;
  final DateTime? cooldownUntil;
  const ProviderStatus({
    required this.provider,
    required this.hasKey,
    required this.enabled,
    required this.state,
    required this.detail,
    this.activeModel,
    this.usedToday = 0,
    this.usedLastMinute = 0,
    this.guardRpm,
    this.guardRpd,
    this.cooldownUntil,
  });
}

class AnthropicClient {
  static const String noKeyMessage =
      "(AI is not connected yet. Open Profile > AI Connection and add a FREE key — Groq takes about 2 minutes. Offline Academy works without it.)";
  static const String offlineMessage =
      "(All free AI services are unavailable or at their free limit right now. Offline mode is active — saved lessons, drills and practice still work, but this is not generative AI.)";

  static String? lastProviderLabel;
  static String? lastModel;
  static bool lastReplyWasOffline = false;

  static QuotaGuard? _quota;
  static Set<String>? _orFree;
  static DateTime? _orFetchedAt;
  static final Set<String> _rejected = {};

  static void resetForTests() {
    _quota = null;
    _orFree = null;
    _orFetchedAt = null;
    _rejected.clear();
    lastProviderLabel = null;
    lastModel = null;
    lastReplyWasOffline = false;
  }

  static Future<QuotaGuard> _guard() async {
    if (_quota != null) return _quota!;
    final g = QuotaGuard(PrefsQuotaStorage());
    await g.load();
    _quota = g;
    return g;
  }

  /// OpenRouter pricing is verified from OpenRouter's own model list.
  /// No list (offline / error) -> nothing verified -> OpenRouter is skipped.
  static Future<Set<String>?> _openRouterFreeIds() async {
    final now = DateTime.now();
    if (_orFree != null && _orFetchedAt != null && now.difference(_orFetchedAt!) < const Duration(hours: 6)) {
      return _orFree;
    }
    final client = ProviderHttp.clientFactory();
    try {
      final r = await client.get(Uri.parse('https://openrouter.ai/api/v1/models')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        _orFree = ZeroCostPolicy.parseOpenRouterFreeIds(r.body);
        _orFetchedAt = now;
        return _orFree;
      }
    } catch (_) {
      // fall through to cached value (if recent) or null
    } finally {
      client.close();
    }
    if (_orFree != null && _orFetchedAt != null && now.difference(_orFetchedAt!) < const Duration(hours: 24)) {
      return _orFree;
    }
    return null;
  }

  static Future<ProviderContext> _context({required bool needOpenRouter}) async {
    return ProviderContext(
      zeroCostOnly: await ApiKeyStore.zeroCostOnly(),
      userVerified: await ApiKeyStore.userVerifiedModels(),
      openRouterFreeIds: needOpenRouter ? await _openRouterFreeIds() : null,
      quota: await _guard(),
    );
  }

  static Future<List<AiProvider>> _orderedProviders() async {
    final priority = await ApiKeyStore.priority();
    final list = priority.map((id) => kAiProviders.firstWhere((p) => p.id == id)).toList();
    // Free providers always come first; paid ones are always last.
    return [...list.where((p) => p.isFree), ...list.where((p) => !p.isFree)];
  }

  static Future<List<MapEntry<AiProvider, String>>> _usable(bool zeroCostOnly) async {
    final out = <MapEntry<AiProvider, String>>[];
    for (final p in await _orderedProviders()) {
      if (!p.isFree && zeroCostOnly) continue;
      if (!await ApiKeyStore.isEnabled(p.id)) continue;
      if (_rejected.contains(p.id)) continue;
      final key = await ApiKeyStore.get(p.id);
      if (key.isEmpty) continue;
      out.add(MapEntry(p, key));
    }
    return out;
  }

  static Future<bool> hasKey() => ApiKeyStore.hasKey();

  static List<Map<String, String>> _normalize(List<Map<String, String>> input) {
    final out = <Map<String, String>>[];
    for (final m in input) {
      final role = m['role'] == 'assistant' ? 'assistant' : 'user';
      final content = (m['content'] ?? '').trim();
      if (content.isEmpty) continue;
      if (out.isNotEmpty && out.last['role'] == role) {
        out.last = {'role': role, 'content': '${out.last['content']}\n$content'};
      } else {
        out.add({'role': role, 'content': content});
      }
    }
    if (out.isEmpty) return [{'role': 'user', 'content': 'Hello'}];
    if (out.first['role'] != 'user') out.insert(0, {'role': 'user', 'content': '(Begin.)'});
    return out;
  }

  static String _cleanReply(String text) => text.replaceAll(RegExp(r'```(?:json|JSON)?'), '').trim();

  static String _offline(String? detail) =>
      detail == null ? offlineMessage : '$offlineMessage Last problem: $detail';

  static void _noteFailure(AiProvider p, ProviderException e) {
    if (e.kind == FailureKind.auth) _rejected.add(p.id);
  }

  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 600,
  }) async {
    final zero = await ApiKeyStore.zeroCostOnly();
    final usable = await _usable(zero);
    if (usable.isEmpty) {
      lastReplyWasOffline = true;
      return noKeyMessage;
    }
    final needOr = usable.any((e) => e.key.id == 'openrouter');
    final ctx = await _context(needOpenRouter: needOr);
    final msgs = _normalize(messages);

    String? lastError;
    for (final entry in usable) {
      ctx.activeModel = null;
      try {
        final text = await entry.key.complete(
          key: entry.value,
          system: systemPrompt,
          messages: msgs,
          maxTokens: maxTokens,
          ctx: ctx,
        );
        lastProviderLabel = entry.key.label;
        lastModel = ctx.activeModel;
        lastReplyWasOffline = false;
        await ctx.quota.save();
        return _cleanReply(text);
      } on ProviderException catch (e) {
        lastError = e.message;
        _noteFailure(entry.key, e);
      } on TimeoutException {
        lastError = '${entry.key.label} took too long.';
      } catch (_) {
        lastError = 'No internet connection or ${entry.key.label} could not be reached.';
      }
    }
    lastReplyWasOffline = true;
    await ctx.quota.save();
    return _offline(lastError);
  }

  static Stream<String> streamMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 300,
  }) async* {
    final zero = await ApiKeyStore.zeroCostOnly();
    final usable = await _usable(zero);
    if (usable.isEmpty) {
      lastReplyWasOffline = true;
      yield noKeyMessage;
      return;
    }
    final needOr = usable.any((e) => e.key.id == 'openrouter');
    final ctx = await _context(needOpenRouter: needOr);
    final msgs = _normalize(messages);

    String? lastError;
    for (final entry in usable) {
      ctx.activeModel = null;
      var gotAny = false;
      try {
        await for (final piece in entry.key.stream(
          key: entry.value,
          system: systemPrompt,
          messages: msgs,
          maxTokens: maxTokens,
          ctx: ctx,
        )) {
          gotAny = true;
          yield piece;
        }
        lastProviderLabel = entry.key.label;
        lastModel = ctx.activeModel;
        lastReplyWasOffline = false;
        await ctx.quota.save();
        return;
      } on ProviderException catch (e) {
        lastError = e.message;
        _noteFailure(entry.key, e);
      } on TimeoutException {
        lastError = '${entry.key.label} took too long.';
      } catch (_) {
        lastError = 'No internet connection or ${entry.key.label} could not be reached.';
      }
      if (gotAny) return; // never mix two models inside one answer
    }
    lastReplyWasOffline = true;
    await ctx.quota.save();
    yield _offline(lastError);
  }

  /// Tests ONE provider with one tiny request (counts toward its quota).
  /// Returns null on success, or a short reason. Nothing is claimed unless
  /// the request was really sent and answered.
  static Future<String?> testProvider(String providerId) async {
    final provider = kAiProviders.firstWhere((p) => p.id == providerId);
    final zero = await ApiKeyStore.zeroCostOnly();
    if (!provider.isFree && zero) return 'Paid provider blocked: zero-cost-only mode is ON.';
    final key = await ApiKeyStore.get(providerId);
    if (key.isEmpty) return 'No key saved for this service.';
    final ctx = await _context(needOpenRouter: providerId == 'openrouter');
    try {
      await provider.complete(
        key: key,
        system: 'Reply with exactly: Connected',
        messages: [
          {'role': 'user', 'content': 'Test'},
        ],
        maxTokens: 20,
        ctx: ctx,
      );
      _rejected.remove(providerId);
      lastProviderLabel = provider.label;
      lastModel = ctx.activeModel;
      await ctx.quota.save();
      return null;
    } on ProviderException catch (e) {
      _noteFailure(provider, e);
      await ctx.quota.save();
      return e.message;
    } on TimeoutException {
      return '${provider.label} took too long. Check your internet.';
    } catch (_) {
      return 'No internet connection or ${provider.label} could not be reached.';
    }
  }

  static void clearRejected(String providerId) => _rejected.remove(providerId);

  /// Real status for the UI — only data this app actually has.
  static Future<List<ProviderStatus>> statuses() async {
    final zero = await ApiKeyStore.zeroCostOnly();
    final ctx = await _context(needOpenRouter: (await ApiKeyStore.get('openrouter')).isNotEmpty);
    final out = <ProviderStatus>[];
    for (final p in await _orderedProviders()) {
      final key = await ApiKeyStore.get(p.id);
      final enabled = await ApiKeyStore.isEnabled(p.id);
      final prefix = '${p.id}|';
      final used = ctx.quota.usedTodayPrefix(prefix);
      final lastMin = ctx.quota.usedLastMinutePrefix(prefix);

      ProviderStatus mk(ProviderState s, String detail,
              {String? model, int? rpm, int? rpd, DateTime? cooldown}) =>
          ProviderStatus(
            provider: p,
            hasKey: key.isNotEmpty,
            enabled: enabled,
            state: s,
            detail: detail,
            activeModel: model,
            usedToday: used,
            usedLastMinute: lastMin,
            guardRpm: rpm,
            guardRpd: rpd,
            cooldownUntil: cooldown,
          );

      if (!p.isFree && zero) {
        out.add(mk(ProviderState.blockedPaid, 'Paid provider blocked: zero-cost-only mode is ON.'));
        continue;
      }
      if (key.isEmpty) {
        out.add(mk(ProviderState.notConfigured, 'No key saved.'));
        continue;
      }
      if (!enabled) {
        out.add(mk(ProviderState.disabledByUser, 'Turned off by you.'));
        continue;
      }
      if (_rejected.contains(p.id)) {
        out.add(mk(ProviderState.keyRejected, 'The provider rejected this key. Check or replace it.'));
        continue;
      }
      final cands = p.candidates(ctx);
      if (cands.isEmpty) {
        final why = p.id == 'openrouter' && ctx.openRouterFreeIds == null
            ? 'Disabled: OpenRouter free pricing could not be verified (no connection).'
            : 'Disabled: no zero-cost-verified model is available for this provider.';
        out.add(mk(ProviderState.noVerifiedModel, why));
        continue;
      }
      ModelCandidate? ready;
      DateTime? soonest;
      for (final c in cands) {
        final q = ctx.quota.check(c.quotaKey, c.rpm, c.rpd);
        if (q.allowed) {
          ready = c;
          break;
        }
        if (q.retryAt != null && (soonest == null || q.retryAt!.isBefore(soonest))) soonest = q.retryAt;
      }
      if (ready == null) {
        out.add(mk(ProviderState.rateLimited, 'Free limit reached (app guard or provider 429). Switching to the next provider.',
            model: cands.first.id, rpm: cands.first.rpm, rpd: cands.first.rpd, cooldown: soonest));
      } else {
        out.add(mk(ProviderState.ready, 'Ready — zero-cost model verified.',
            model: ready.id, rpm: ready.rpm, rpd: ready.rpd));
      }
    }
    return out;
  }
}
