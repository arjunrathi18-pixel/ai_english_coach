import 'dart:async';
import 'ai_providers.dart';
import 'api_key_store.dart';

/// Single entry point for every AI feature in the app (the class keeps its
/// original name so no other file had to change).
///
///  - Uses every service you added a key for (Groq, Cerebras, Gemini,
///    OpenRouter — all free — or Anthropic), fastest first.
///  - If one is busy / rate-limited / rejects the key, it silently moves
///    to the next, so several free tiers add up.
///  - sendMessage returns the whole reply; streamMessage yields text as it
///    is written so voice chat can start talking within about a second.
///  - Failures never throw: they return a short "(...)" explanation.
class AnthropicClient {
  static const String noKeyMessage =
      "(AI is not connected yet. Open Profile > AI Connection and add a FREE key — Groq takes about 2 minutes.)";

  /// Which service answered last (shown in AI Connection for transparency).
  static String? lastProviderLabel;

  static Future<bool> hasKey() => ApiKeyStore.hasKey();

  static Future<List<MapEntry<AiProvider, String>>> _active() async {
    final out = <MapEntry<AiProvider, String>>[];
    for (final p in kAiProviders) {
      final key = await ApiKeyStore.get(p.id);
      if (key.isNotEmpty) out.add(MapEntry(p, key));
    }
    return out;
  }

  /// The chat APIs need: first message from the user, alternating roles.
  /// Our screens often open with the AI's line (roleplay, interview,
  /// meeting) or end up with two user turns in a row — fix that once here.
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
    if (out.first['role'] != 'user') {
      out.insert(0, {'role': 'user', 'content': '(Begin.)'});
    }
    return out;
  }

  /// Open-source models sometimes wrap JSON in ``` fences; our parsers want
  /// plain JSON between the markers, so strip the fences.
  static String _cleanReply(String text) =>
      text.replaceAll(RegExp(r'```(?:json|JSON)?'), '').trim();

  static String _failMessage(String? detail) =>
      "(The AI could not answer right now. ${detail ?? ''} Check your internet or add another free key in Profile > AI Connection.)";

  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 600,
  }) async {
    final active = await _active();
    if (active.isEmpty) return noKeyMessage;
    final msgs = _normalize(messages);

    String? lastError;
    for (final entry in active) {
      try {
        final text = await entry.key.complete(
          key: entry.value,
          system: systemPrompt,
          messages: msgs,
          maxTokens: maxTokens,
        );
        lastProviderLabel = entry.key.label;
        return _cleanReply(text);
      } on ProviderException catch (e) {
        lastError = e.message;
      } on TimeoutException {
        lastError = '${entry.key.label} took too long.';
      } catch (_) {
        lastError = 'No internet connection or ${entry.key.label} could not be reached.';
      }
    }
    return _failMessage(lastError);
  }

  /// Streams the reply in small text pieces as the model writes it.
  static Stream<String> streamMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 300,
  }) async* {
    final active = await _active();
    if (active.isEmpty) {
      yield noKeyMessage;
      return;
    }
    final msgs = _normalize(messages);

    String? lastError;
    for (final entry in active) {
      var gotAny = false;
      try {
        await for (final piece in entry.key.stream(
          key: entry.value,
          system: systemPrompt,
          messages: msgs,
          maxTokens: maxTokens,
        )) {
          gotAny = true;
          yield piece;
        }
        lastProviderLabel = entry.key.label;
        return;
      } on ProviderException catch (e) {
        lastError = e.message;
      } on TimeoutException {
        lastError = '${entry.key.label} took too long.';
      } catch (_) {
        lastError = 'No internet connection or ${entry.key.label} could not be reached.';
      }
      // If part of the answer was already sent, do not mix in another model.
      if (gotAny) return;
    }
    yield _failMessage(lastError);
  }

  /// Tests ONE service (used by the AI Connection screen).
  /// Returns null on success, or a short reason on failure.
  static Future<String?> testProvider(String providerId) async {
    final key = await ApiKeyStore.get(providerId);
    if (key.isEmpty) return 'No key saved for this service.';
    final provider = kAiProviders.firstWhere((p) => p.id == providerId);
    try {
      await provider.complete(
        key: key,
        system: 'Reply with exactly: Connected',
        messages: [
          {'role': 'user', 'content': 'Test'},
        ],
        maxTokens: 20,
      );
      return null;
    } on ProviderException catch (e) {
      return e.message;
    } on TimeoutException {
      return '${provider.label} took too long. Check your internet.';
    } catch (_) {
      return 'No internet connection or ${provider.label} could not be reached.';
    }
  }
}
