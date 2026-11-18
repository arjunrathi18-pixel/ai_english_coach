import 'dart:convert';
import 'anthropic_client.dart';
import 'vocabulary_prompts.dart';
import 'vocabulary_item.dart';

class VocabularyService {
  Future<VocabularyItem?> explain({
    required String wordOrPhrase,
    required String accent,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kVocabularyExplainSystemPrompt,
      messages: [
        {
          "role": "user",
          "content":
              "Word/phrase: \"$wordOrPhrase\"\nLearner level: $level\nPreferred accent: $accent",
        },
      ],
      maxTokens: 400,
    );

    final start = reply.indexOf('<<<VOCAB_EXPLANATION>>>');
    final end = reply.indexOf('<<<END_VOCAB_EXPLANATION>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<VOCAB_EXPLANATION>>>'.length, end).trim();
    try {
      return VocabularyItem.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Returns (usedCorrectly, feedback, countsTowardMastery), or null if
  /// evaluation failed.
  Future<(bool, String, bool)?> evaluate({
    required VocabularyItem item,
    required String learnerAttempt,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kVocabularyEvaluationSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Target word/phrase: \"${item.word}\"\n"
              "Practice prompt given: \"${item.practicePrompt}\"\n"
              "Learner's attempt: \"$learnerAttempt\"",
        },
      ],
      maxTokens: 200,
    );

    final start = reply.indexOf('<<<VOCAB_EVALUATION>>>');
    final end = reply.indexOf('<<<END_VOCAB_EVALUATION>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<VOCAB_EVALUATION>>>'.length, end).trim();
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return (
        json['usedCorrectly'] as bool,
        json['feedback'] as String,
        json['countsTowardMastery'] as bool,
      );
    } catch (_) {
      return null;
    }
  }
}
