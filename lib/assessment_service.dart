import 'dart:convert';
import 'anthropic_client.dart';
import 'assessment_prompts.dart';
import 'chat_message.dart';
import 'learner_profile.dart';

const String _resultStartMarker = '<<<ASSESSMENT_RESULT>>>';
const String _resultEndMarker = '<<<END_ASSESSMENT_RESULT>>>';

class AssessmentService {
  /// Sends the assessment conversation so far and gets the AI's next
  /// question (or, if the assessment is complete, its closing message
  /// with the embedded result block still attached).
  Future<String> getNextTurn(List<ChatMessage> history) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    return AnthropicClient.sendMessage(
      systemPrompt: kLevelAssessmentSystemPrompt,
      messages: messages,
      maxTokens: 700,
    );
  }

  /// Returns the learner-facing text only, with the machine-readable
  /// result block (if present) stripped out.
  String stripResultBlock(String aiReply) {
    final start = aiReply.indexOf(_resultStartMarker);
    if (start == -1) return aiReply;
    return aiReply.substring(0, start).trim();
  }

  /// Returns a parsed LearnerProfile if this reply contains the final
  /// result block, or null if the assessment is still in progress.
  LearnerProfile? tryParseResult(String aiReply) {
    final start = aiReply.indexOf(_resultStartMarker);
    final end = aiReply.indexOf(_resultEndMarker);
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        aiReply.substring(start + _resultStartMarker.length, end).trim();

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LearnerProfile.fromJson(map);
    } catch (_) {
      // Model didn't return valid JSON this time — treat as still in
      // progress rather than crashing the assessment flow.
      return null;
    }
  }
}
