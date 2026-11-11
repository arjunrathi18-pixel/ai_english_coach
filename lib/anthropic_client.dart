import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_key_store.dart';

/// Shared wrapper around the Anthropic Messages API. Every AI feature in
/// the app goes through here.
///  - Key comes from ApiKeyStore (in-app key first, build key second).
///  - A fast model is tried first; if the account has no access to it the
///    client automatically falls back to the next one and remembers the
///    one that worked.
///  - sendMessage returns the full reply; streamMessage yields text as it
///    is generated so voice chat can start speaking within ~1 second.
///  - Failures never throw: they return a short "(...)" explanation.
class AnthropicClient {
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';

  /// Fast model first (low latency for voice), then stronger fallbacks.
  static const List<String> _modelChain = [
    'claude-haiku-5-5',
    'claude-sonnet-5-5',
    'claude-sonnet-4-6',
  ];
  static String? _workingModel;

  static const String noKeyMessage =
      "(AI is not connected yet. Open Profile > AI Connection and add your Anthropic API key.)";

  static Future<bool> hasKey() => ApiKeyStore.hasKey();

  static List<String> _modelOrder() {
    if (_workingModel == null) return _modelChain;
    return [_workingModel!, ..._modelChain.where((m) => m != _workingModel)];
  }

  static bool _isModelProblem(int status, String body) {
    if (status == 404) return true;
    if (status == 400 && body.toLowerCase().contains('model')) return true;
    return false;
  }

  static String _errorMessage(int status) {
    switch (status) {
      case 401:
      case 403:
        return "(Your API key was rejected ($status). Please check it in Profile > AI Connection.)";
      case 429:
        return "(The AI is busy or the key's rate limit was reached. Please try again in a moment.)";
      case 529:
      case 500:
      case 502:
      case 503:
        return "(The AI service is temporarily unavailable ($status). Please try again.)";
      default:
        return "(Error talking to the AI: $status. Please try again.)";
    }
  }

  /// The Messages API needs: first message from the user, and roles that
  /// alternate. Our screens often open with the AI's line (roleplay,
  /// interview, meeting) or end up with two user turns in a row — fix that
  /// here once so every feature is safe.
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

  static Map<String, String> _headers(String key) => {
        "Content-Type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
      };

  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 600,
  }) async {
    final key = await ApiKeyStore.get();
    if (key.isEmpty) return noKeyMessage;

    try {
      for (final model in _modelOrder()) {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: _headers(key),
              body: jsonEncode({
                "model": model,
                "max_tokens": maxTokens,
                "system": systemPrompt,
                "messages": _normalize(messages),
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          if (_isModelProblem(response.statusCode, response.body)) continue;
          return _errorMessage(response.statusCode);
        }

        _workingModel = model;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        final text = content
            .where((block) => block['type'] == 'text')
            .map((block) => block['text'] as String)
            .join('\n');
        return text.trim().isEmpty ? "(No response received — please try again.)" : text.trim();
      }
      return "(No supported AI model is available for this API key.)";
    } on TimeoutException {
      return "(The AI took too long to respond. Check your internet and try again.)";
    } catch (_) {
      return "(No internet connection or the AI could not be reached.)";
    }
  }

  /// Streams the reply in small text pieces as the model writes it.
  static Stream<String> streamMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 300,
  }) async* {
    final key = await ApiKeyStore.get();
    if (key.isEmpty) {
      yield noKeyMessage;
      return;
    }

    final client = http.Client();
    try {
      for (final model in _modelOrder()) {
        final request = http.Request('POST', Uri.parse(_endpoint))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode({
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": _normalize(messages),
            "stream": true,
          });

        final response = await client.send(request).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          if (_isModelProblem(response.statusCode, body)) continue;
          yield _errorMessage(response.statusCode);
          return;
        }

        _workingModel = model;
        var buffer = '';
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
                  yield delta['text'] as String;
                }
              }
            } catch (_) {
              // ignore a malformed partial line
            }
          }
        }
        return;
      }
      yield "(No supported AI model is available for this API key.)";
    } on TimeoutException {
      yield "(The AI took too long to respond. Check your internet and try again.)";
    } catch (_) {
      yield "(No internet connection or the AI could not be reached.)";
    } finally {
      client.close();
    }
  }
}
