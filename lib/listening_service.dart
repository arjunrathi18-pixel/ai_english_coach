import 'dart:convert';
import 'anthropic_client.dart';
import 'listening_prompts.dart';
import 'listening_models.dart';

class ListeningService {
  Future<ListeningPassage?> generatePassage({
    required String level,
    required String accent,
    String topic = '',
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kListeningPassageSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Learner level: $level\n"
              "Preferred accent: $accent\n"
              "Topic/focus: ${topic.isEmpty ? 'general conversation' : topic}",
        },
      ],
      maxTokens: 500,
    );

    final start = reply.indexOf('<<<LISTENING_PASSAGE>>>');
    final end = reply.indexOf('<<<END_LISTENING_PASSAGE>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<LISTENING_PASSAGE>>>'.length, end).trim();
    try {
      return ListeningPassage.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ListeningAnswerResult?> evaluateAnswer({
    required ListeningPassage passage,
    required ListeningQuestion question,
    required String learnerAnswer,
    required bool isFirstAttempt,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kListeningAnswerEvalSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Passage: \"${passage.script}\"\n"
              "Question: \"${question.text}\"\n"
              "Expected answer points: \"${question.expectedAnswerPoints}\"\n"
              "Learner's answer: \"$learnerAnswer\"",
        },
      ],
      maxTokens: 200,
    );

    final start = reply.indexOf('<<<LISTENING_ANSWER_EVAL>>>');
    final end = reply.indexOf('<<<END_LISTENING_ANSWER_EVAL>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr = reply
        .substring(start + '<<<LISTENING_ANSWER_EVAL>>>'.length, end)
        .trim();
    try {
      return ListeningAnswerResult.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
        wasFirstAttempt: isFirstAttempt,
      );
    } catch (_) {
      return null;
    }
  }
}
