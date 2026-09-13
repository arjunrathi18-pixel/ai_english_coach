import 'dart:convert';
import 'package:http/http.dart' as http;

import 'system_prompts.dart';
import 'chat_message.dart';
import 'session_settings.dart';

/// Wraps calls to the Anthropic Messages API.
///
/// SETUP: Put your Anthropic API key somewhere safe — do NOT hardcode it
/// in source that goes to a public GitHub repo. Recommended: pass it in
/// at build time with --dart-define, e.g.
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-xxxx
/// and read it here via String.fromEnvironment.
class AiTutorService {
  static const String _apiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';

  /// Sends the conversation so far plus current session settings and
  /// returns the tutor's next reply as plain text.
  Future<String> getNextReply({
    required List<ChatMessage> history,
    required SessionSettings settings,
  }) async {
    if (_apiKey.isEmpty) {
      return "(Dev note: no ANTHROPIC_API_KEY configured. Run with "
          "--dart-define=ANTHROPIC_API_KEY=your_key to enable real replies.)";
    }

    final systemPrompt = kMasterBrainPrompt +
        "\n\n" +
        buildSessionContextPrompt(
          mode: settings.mode,
          correctionMode: settings.correctionMode,
          estimatedLevel: settings.estimatedLevel,
          accent: settings.accent,
        );

    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "x-api-key": _apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: jsonEncode({
        "model": _model,
        "max_tokens": 500,
        "system": systemPrompt,
        "messages": messages,
      }),
    );

    if (response.statusCode != 200) {
      return "(Error talking to the tutor: ${response.statusCode}. "
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
