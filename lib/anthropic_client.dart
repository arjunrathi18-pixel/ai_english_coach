import 'dart:convert';
import 'package:http/http.dart' as http;

/// Shared low-level wrapper around the Anthropic Messages API.
/// Both the everyday tutor conversation (ai_tutor_service.dart) and the
/// level assessment engine (assessment_service.dart) call through this,
/// so the API key / endpoint / model only need to be configured in one
/// place.
class AnthropicClient {
  static const String _apiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';

  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// [messages] must be a list of {"role": "user"|"assistant", "content": "..."}
  /// in chronological order, starting with a user message.
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 600,
  }) async {
    if (_apiKey.isEmpty) {
      return "(Dev note: no ANTHROPIC_API_KEY configured. Run with "
          "--dart-define=ANTHROPIC_API_KEY=your_key to enable real replies.)";
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "x-api-key": _apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: jsonEncode({
        "model": _model,
        "max_tokens": maxTokens,
        "system": systemPrompt,
        "messages": messages,
      }),
    );

    if (response.statusCode != 200) {
      return "(Error talking to the AI: ${response.statusCode}. "
          "Please try again in a moment.)";
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final text = content
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String)
        .join('\n');

    return text.trim().isEmpty
        ? "(No response received — please try again.)"
        : text.trim();
  }
}
