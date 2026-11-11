import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// One AI service the app can talk to. The app can hold several keys at
/// once (all FREE ones are supported) and automatically moves to the next
/// service when one is busy, rate-limited or rejects the key.
class ProviderException implements Exception {
  final String message;
  ProviderException(this.message);
  @override
  String toString() => message;
}

abstract class AiProvider {
  String get id;
  String get label;
  String get tagline;
  String get signupUrl;
  bool get isFree;

  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  });

  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  });
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

/// Works for every service that speaks the OpenAI chat format:
/// Groq, Cerebras, Google Gemini (OpenAI-compatible endpoint), OpenRouter.
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
  final bool isFree;
  final String baseUrl;
  final List<String> models;

  OpenAiCompatProvider({
    required this.id,
    required this.label,
    required this.tagline,
    required this.signupUrl,
    required this.baseUrl,
    required this.models,
    this.isFree = true,
  });

  Map<String, String> _headers(String key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      };

  List<Map<String, String>> _messages(String system, List<Map<String, String>> msgs) => [
        {'role': 'system', 'content': system},
        ...msgs,
      ];

  /// Statuses where trying the NEXT MODEL of the same service can help
  /// (each model has its own limits / may have been retired).
  bool _tryNextModel(int status) => status == 404 || status == 429 || status == 413 || status == 400;

  @override
  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  }) async {
    String lastError = '$label is unavailable.';
    for (final model in models) {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: _headers(key),
            body: jsonEncode({
              'model': model,
              'messages': _messages(system, messages),
              'max_tokens': maxTokens,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>? ?? [];
        if (choices.isEmpty) {
          lastError = '$label returned an empty answer.';
          continue;
        }
        final content = (choices.first['message']?['content'] ?? '').toString().trim();
        if (content.isEmpty) {
          lastError = '$label returned an empty answer.';
          continue;
        }
        return content;
      }
      lastError = _statusText(label, response.statusCode);
      if (!_tryNextModel(response.statusCode)) throw ProviderException(lastError);
    }
    throw ProviderException(lastError);
  }

  @override
  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  }) async* {
    String lastError = '$label is unavailable.';
    final client = http.Client();
    try {
      for (final model in models) {
        final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode({
            'model': model,
            'messages': _messages(system, messages),
            'max_tokens': maxTokens,
            'temperature': 0.7,
            'stream': true,
          });
        final response = await client.send(request).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          await response.stream.drain<void>();
          lastError = _statusText(label, response.statusCode);
          if (!_tryNextModel(response.statusCode)) throw ProviderException(lastError);
          continue;
        }

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
              final delta = choices.first['delta'] as Map<String, dynamic>?;
              final text = delta?['content'];
              if (text is String && text.isNotEmpty) {
                gotText = true;
                yield text;
              }
            } catch (_) {
              // ignore a malformed partial line
            }
          }
        }
        if (gotText) return;
        lastError = '$label returned an empty answer.';
      }
      throw ProviderException(lastError);
    } finally {
      client.close();
    }
  }
}

/// Anthropic's own API (paid) — optional, kept for anyone who has a key.
class AnthropicProvider implements AiProvider {
  @override
  String get id => 'anthropic';
  @override
  String get label => 'Anthropic Claude';
  @override
  String get tagline => 'Paid. Best quality if you already have a key.';
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

  bool _modelProblem(int status, String body) =>
      status == 404 || (status == 400 && body.toLowerCase().contains('model'));

  @override
  Future<String> complete({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  }) async {
    String lastError = '$label is unavailable.';
    for (final model in _models) {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers(key),
            body: jsonEncode({
              'model': model,
              'max_tokens': maxTokens,
              'system': system,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        final text = content
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join('\n')
            .trim();
        if (text.isEmpty) throw ProviderException('$label returned an empty answer.');
        return text;
      }
      lastError = _statusText(label, response.statusCode);
      if (!_modelProblem(response.statusCode, response.body)) throw ProviderException(lastError);
    }
    throw ProviderException(lastError);
  }

  @override
  Stream<String> stream({
    required String key,
    required String system,
    required List<Map<String, String>> messages,
    required int maxTokens,
  }) async* {
    String lastError = '$label is unavailable.';
    final client = http.Client();
    try {
      for (final model in _models) {
        final request = http.Request('POST', Uri.parse(_endpoint))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            'system': system,
            'messages': messages,
            'stream': true,
          });
        final response = await client.send(request).timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          lastError = _statusText(label, response.statusCode);
          if (!_modelProblem(response.statusCode, body)) throw ProviderException(lastError);
          continue;
        }
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
        lastError = '$label returned an empty answer.';
      }
      throw ProviderException(lastError);
    } finally {
      client.close();
    }
  }
}

/// All supported services, in the order the app tries them
/// (fastest free first).
final List<AiProvider> kAiProviders = [
  OpenAiCompatProvider(
    id: 'groq',
    label: 'Groq',
    tagline: 'Fastest. Free, no credit card. Start here.',
    signupUrl: 'console.groq.com/keys',
    baseUrl: 'https://api.groq.com/openai/v1',
    models: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
  ),
  OpenAiCompatProvider(
    id: 'cerebras',
    label: 'Cerebras',
    tagline: 'Very fast. Free, no credit card.',
    signupUrl: 'cloud.cerebras.ai',
    baseUrl: 'https://api.cerebras.ai/v1',
    models: ['llama-3.3-70b', 'gpt-oss-120b', 'llama3.1-8b'],
  ),
  OpenAiCompatProvider(
    id: 'gemini',
    label: 'Google Gemini',
    tagline: 'Free with a Google account.',
    signupUrl: 'aistudio.google.com/apikey',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    models: ['gemini-2.5-flash-lite', 'gemini-2.5-flash', 'gemini-3.5-flash-lite', 'gemini-3.8-flash'],
  ),
  OpenAiCompatProvider(
    id: 'openrouter',
    label: 'OpenRouter',
    tagline: 'Free models, small daily limit. Good backup.',
    signupUrl: 'openrouter.ai/keys',
    baseUrl: 'https://openrouter.ai/api/v1',
    models: ['meta-llama/llama-3.3-70b-instruct:free', 'openai/gpt-oss-120b:free'],
  ),
  AnthropicProvider(),
];
