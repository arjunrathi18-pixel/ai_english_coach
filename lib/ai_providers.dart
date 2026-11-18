import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'quota_guard.dart';
import 'zero_cost_policy.dart';

enum FailureKind { auth, rateLimit, policy, server, empty, other }

class ProviderException implements Exception {
  final String message;
  final FailureKind kind;
  final Duration? retryAfter;
  ProviderException(this.message, this.kind, {this.retryAfter});
  @override
  String toString() => message;
}

/// All network traffic goes through this factory so tests can inject a mock.
class ProviderHttp {
  static http.Client Function() clientFactory = () => http.Client();
}

/// What a provider needs to know to stay inside the zero-cost policy.
class ProviderContext {
  final bool zeroCostOnly;
  final Set<String> userVerified;
  final Set<String>? openRouterFreeIds;
  final QuotaGuard quota;
  String? activeModel;
  ProviderContext({
    required this.zeroCostOnly,
    required this.userVerified,
    required this.openRouterFreeIds,
    required this.quota,
  });
}

class ModelCandidate {
  final String id;
  final int rpm;
  final int rpd;
  final String quotaKey;
  const ModelCandidate(this.id, this.rpm, this.rpd, this.quotaKey);
}

abstract class AiProvider {
  String get id;
  String get label;
  String get tagline;
  String get signupUrl;
  bool get isFree;

  /// Models this provider may use RIGHT NOW (already passed the policy).
  List<ModelCandidate> candidates(ProviderContext ctx);

  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  });

  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  });
}

Duration? _retryAfter(Map<String, String> headers) {
  final v = headers['retry-after'];
  if (v == null) return null;
  final secs = int.tryParse(v.trim());
  if (secs == null || secs < 0) return null;
  return Duration(seconds: secs);
}

String _statusText(String who, int status) {
  switch (status) {
    case 401:
    case 403:
      return '$who rejected the API key ($status).';
    case 429:
      return '$who is rate-limited right now (429).';
    case 413:
      return '$who says the request is too large (413).';
    default:
      return '$who returned an error ($status).';
  }
}

/// Shared request flow: checks quota before each model, records usage,
/// turns a 429 into a cool-down, and decides whether to try the next model.
/// Returns null to mean "try the next candidate".
ProviderException? _classify(
  String label,
  int status,
  Map<String, String> headers,
  ModelCandidate c,
  ProviderContext ctx,
) {
  if (status == 401 || status == 403) {
    return ProviderException(_statusText(label, status), FailureKind.auth);
  }
  if (status == 429) {
    final ra = _retryAfter(headers);
    ctx.quota.markRateLimited(c.quotaKey, retryAfter: ra);
    return ProviderException(_statusText(label, status), FailureKind.rateLimit, retryAfter: ra);
  }
  if (status == 404 || status == 400 || status == 413) {
    return ProviderException(_statusText(label, status), FailureKind.other);
  }
  if (status >= 500) {
    return ProviderException(_statusText(label, status), FailureKind.server);
  }
  return ProviderException(_statusText(label, status), FailureKind.other);
}

/// Groq, Cerebras, Google Gemini (OpenAI-compatible endpoint) and
/// OpenRouter all speak the OpenAI chat format.
class OpenAiCompatProvider implements AiProvider {
  @override
  final String id;
  @override
  final String label;
  @override
  final String tagline;
  @override
  final String signupUrl;
  @override
  bool get isFree => true;
  final String baseUrl;

  OpenAiCompatProvider({
    required this.id,
    required this.label,
    required this.tagline,
    required this.signupUrl,
    required this.baseUrl,
  });

  Map<String, String> _headers(String key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      };

  @override
  List<ModelCandidate> candidates(ProviderContext ctx) {
    final out = <ModelCandidate>[];
    if (id == 'openrouter') {
      final ids = ctx.openRouterFreeIds;
      if (ids == null) return out;
      for (final m in ZeroCostPolicy.orderOpenRouter(ids)) {
        final d = ZeroCostPolicy.check(
          provider: id,
          modelId: m,
          zeroCostOnly: ctx.zeroCostOnly,
          openRouterFreeIds: ids,
        );
        if (d.allowed) {
          out.add(ModelCandidate(m, ZeroCostPolicy.openRouterRpm, ZeroCostPolicy.openRouterRpd, 'openrouter|*'));
        }
      }
      return out;
    }
    for (final spec in ZeroCostPolicy.allowlistFor(id, userVerified: ctx.userVerified)) {
      final d = ZeroCostPolicy.check(
        provider: id,
        modelId: spec.id,
        zeroCostOnly: ctx.zeroCostOnly,
        userVerified: ctx.userVerified,
      );
      if (d.allowed) out.add(ModelCandidate(spec.id, spec.rpm, spec.rpd, '$id|${spec.id}'));
    }
    return out;
  }

  List<Map<String, String>> _messages(String system, List<Map<String, String>> msgs) => [
        {'role': 'system', 'content': system},
        ...msgs,
      ];

  @override
  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  }) async {
    final cands = candidates(ctx);
    if (cands.isEmpty) {
      throw ProviderException('$label has no zero-cost-verified model available.', FailureKind.policy);
    }
    ProviderException? last;
    for (final c in cands) {
      final q = ctx.quota.check(c.quotaKey, c.rpm, c.rpd);
      if (!q.allowed) {
        last = ProviderException('$label: ${q.reason}.', FailureKind.rateLimit);
        continue;
      }
      ctx.quota.record(c.quotaKey);
      final client = ProviderHttp.clientFactory();
      try {
        final response = await client
            .post(
              Uri.parse('$baseUrl/chat/completions'),
              headers: _headers(key),
              body: jsonEncode({
                'model': c.id,
                'messages': _messages(system, messages),
                'max_tokens': maxTokens,
                'temperature': 0.7,
              }),
            )
            .timeout(const Duration(seconds: 40));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>? ?? [];
          final content = choices.isEmpty ? '' : (choices.first['message']?['content'] ?? '').toString().trim();
          if (content.isEmpty) {
            last = ProviderException('$label returned an empty answer.', FailureKind.empty);
            continue;
          }
          ctx.activeModel = c.id;
          return content;
        }
        final err = _classify(label, response.statusCode, response.headers, c, ctx);
        if (err!.kind == FailureKind.auth) throw err;
        last = err;
      } finally {
        client.close();
      }
    }
    throw last ?? ProviderException('$label is unavailable.', FailureKind.other);
  }

  @override
  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  }) async* {
    final cands = candidates(ctx);
    if (cands.isEmpty) {
      throw ProviderException('$label has no zero-cost-verified model available.', FailureKind.policy);
    }
    ProviderException? last;
    for (final c in cands) {
      final q = ctx.quota.check(c.quotaKey, c.rpm, c.rpd);
      if (!q.allowed) {
        last = ProviderException('$label: ${q.reason}.', FailureKind.rateLimit);
        continue;
      }
      ctx.quota.record(c.quotaKey);
      final client = ProviderHttp.clientFactory();
      try {
        final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode({
            'model': c.id,
            'messages': _messages(system, messages),
            'max_tokens': maxTokens,
            'temperature': 0.7,
            'stream': true,
          });
        final response = await client.send(request).timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          await response.stream.drain<void>();
          final err = _classify(label, response.statusCode, response.headers, c, ctx);
          if (err!.kind == FailureKind.auth) throw err;
          last = err;
          continue;
        }
        ctx.activeModel = c.id;
        var buffer = '';
        var gotText = false;
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            final l = line.trim();
            if (!l.startsWith('data:')) continue;
            final data = l.substring(5).trim();
            if (data.isEmpty || data == '[DONE]') continue;
            try {
              final j = jsonDecode(data) as Map<String, dynamic>;
              final choices = j['choices'] as List<dynamic>? ?? [];
              if (choices.isEmpty) continue;
              final text = (choices.first['delta'] as Map<String, dynamic>?)?['content'];
              if (text is String && text.isNotEmpty) {
                gotText = true;
                yield text;
              }
            } catch (_) {}
          }
        }
        if (gotText) return;
        last = ProviderException('$label returned an empty answer.', FailureKind.empty);
      } finally {
        client.close();
      }
    }
    throw last ?? ProviderException('$label is unavailable.', FailureKind.other);
  }
}

/// OPTIONAL and PAID. Lowest priority, and blocked by the policy unless the
/// user switches "Zero-cost-only" OFF on purpose.
class AnthropicProvider implements AiProvider {
  @override
  String get id => 'anthropic';
  @override
  String get label => 'Anthropic Claude (paid)';
  @override
  String get tagline => 'Optional. PAID. Used only as the very last fallback, and only if zero-cost-only mode is OFF.';
  @override
  String get signupUrl => 'console.anthropic.com';
  @override
  bool get isFree => false;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _models = ['claude-haiku-5-5', 'claude-sonnet-5-5', 'claude-sonnet-4-6'];

  Map<String, String> _headers(String key) => {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      };

  @override
  List<ModelCandidate> candidates(ProviderContext ctx) {
    final out = <ModelCandidate>[];
    for (final m in _models) {
      final d = ZeroCostPolicy.check(provider: id, modelId: m, zeroCostOnly: ctx.zeroCostOnly);
      if (d.allowed) out.add(ModelCandidate(m, 40, 100000, 'anthropic|$m'));
    }
    return out;
  }

  @override
  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  }) async {
    final cands = candidates(ctx);
    if (cands.isEmpty) {
      throw ProviderException('Paid provider blocked: zero-cost-only mode is ON.', FailureKind.policy);
    }
    ProviderException? last;
    for (final c in cands) {
      final q = ctx.quota.check(c.quotaKey, c.rpm, c.rpd);
      if (!q.allowed) {
        last = ProviderException('$label: ${q.reason}.', FailureKind.rateLimit);
        continue;
      }
      ctx.quota.record(c.quotaKey);
      final client = ProviderHttp.clientFactory();
      try {
        final response = await client
            .post(
              Uri.parse(_endpoint),
              headers: _headers(key),
              body: jsonEncode({'model': c.id, 'max_tokens': maxTokens, 'system': system, 'messages': messages}),
            )
            .timeout(const Duration(seconds: 45));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = (data['content'] as List<dynamic>)
              .where((b) => b['type'] == 'text')
              .map((b) => b['text'] as String)
              .join('\n')
              .trim();
          if (text.isEmpty) {
            last = ProviderException('$label returned an empty answer.', FailureKind.empty);
            continue;
          }
          ctx.activeModel = c.id;
          return text;
        }
        final err = _classify(label, response.statusCode, response.headers, c, ctx);
        if (err!.kind == FailureKind.auth) throw err;
        last = err;
      } finally {
        client.close();
      }
    }
    throw last ?? ProviderException('$label is unavailable.', FailureKind.other);
  }

  @override
  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required ProviderContext ctx,
  }) async* {
    final cands = candidates(ctx);
    if (cands.isEmpty) {
      throw ProviderException('Paid provider blocked: zero-cost-only mode is ON.', FailureKind.policy);
    }
    ProviderException? last;
    for (final c in cands) {
      final q = ctx.quota.check(c.quotaKey, c.rpm, c.rpd);
      if (!q.allowed) {
        last = ProviderException('$label: ${q.reason}.', FailureKind.rateLimit);
        continue;
      }
      ctx.quota.record(c.quotaKey);
      final client = ProviderHttp.clientFactory();
      try {
        final request = http.Request('POST', Uri.parse(_endpoint))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode({
            'model': c.id,
            'max_tokens': maxTokens,
            'system': system,
            'messages': messages,
            'stream': true,
          });
        final response = await client.send(request).timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          await response.stream.drain<void>();
          final err = _classify(label, response.statusCode, response.headers, c, ctx);
          if (err!.kind == FailureKind.auth) throw err;
          last = err;
          continue;
        }
        ctx.activeModel = c.id;
        var buffer = '';
        var gotText = false;
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (!line.startsWith('data:')) continue;
            final data = line.substring(5).trim();
            if (data.isEmpty || data == '[DONE]') continue;
            try {
              final j = jsonDecode(data) as Map<String, dynamic>;
              if (j['type'] == 'content_block_delta') {
                final delta = j['delta'] as Map<String, dynamic>?;
                if (delta != null && delta['type'] == 'text_delta') {
                  gotText = true;
                  yield delta['text'] as String;
                }
              }
            } catch (_) {}
          }
        }
        if (gotText) return;
        last = ProviderException('$label returned an empty answer.', FailureKind.empty);
      } finally {
        client.close();
      }
    }
    throw last ?? ProviderException('$label is unavailable.', FailureKind.other);
  }
}

/// Default priority: free services first (fastest first), paid LAST.
final List<AiProvider> kAiProviders = [
  OpenAiCompatProvider(
    id: 'groq',
    label: 'Groq',
    tagline: 'Primary. Fastest. Free tier, no credit card.',
    signupUrl: 'console.groq.com/keys',
    baseUrl: 'https://api.groq.com/openai/v1',
  ),
  OpenAiCompatProvider(
    id: 'cerebras',
    label: 'Cerebras',
    tagline: 'Secondary. Used only if your account really has the free tier.',
    signupUrl: 'cloud.cerebras.ai',
    baseUrl: 'https://api.cerebras.ai/v1',
  ),
  OpenAiCompatProvider(
    id: 'gemini',
    label: 'Google Gemini',
    tagline: 'Free-tier models only. Never enable billing on the project.',
    signupUrl: 'aistudio.google.com/apikey',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
  ),
  OpenAiCompatProvider(
    id: 'openrouter',
    label: 'OpenRouter (free models)',
    tagline: 'Emergency backup. Only models verified as \$0 input and output.',
    signupUrl: 'openrouter.ai/keys',
    baseUrl: 'https://openrouter.ai/api/v1',
  ),
  AnthropicProvider(),
];
