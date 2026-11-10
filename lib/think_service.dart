import 'dart:convert';
import 'anthropic_client.dart';
import 'think_prompts.dart';

class ThinkFeedback {
  final String strength;
  final String gentleNote;
  final String nextStep;
  ThinkFeedback({required this.strength, required this.gentleNote, required this.nextStep});
}

class ThinkService {
  Future<ThinkFeedback?> getFeedback({
    required String mission,
    required String response,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kThinkInEnglishPrompt,
      messages: [
        {"role": "user", "content": "Mission: $mission\nLevel: $level\nLearner's response: $response"},
      ],
      maxTokens: 350,
    );
    const start = '<<<THINK_FEEDBACK>>>';
    const end = '<<<END_THINK_FEEDBACK>>>';
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      final m = jsonDecode(reply.substring(s + start.length, e).trim()) as Map<String, dynamic>;
      return ThinkFeedback(
        strength: m['strength'] as String,
        gentleNote: m['gentleNote'] as String? ?? '',
        nextStep: m['nextStep'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
