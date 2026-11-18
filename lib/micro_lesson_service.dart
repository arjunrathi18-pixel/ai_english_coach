import 'dart:convert';
import 'anthropic_client.dart';
import 'micro_lesson_prompts.dart';
import 'micro_lesson.dart';

class MicroLessonService {
  Future<MicroLesson?> generate(String mistakePattern) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kMicroLessonSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Recurring mistake pattern: $mistakePattern",
        },
      ],
      maxTokens: 400,
    );

    return _extract(reply, '<<<MICRO_LESSON>>>', '<<<END_MICRO_LESSON>>>',
        MicroLesson.fromJson);
  }

  /// Returns (isCorrect, feedback), or null if evaluation failed.
  Future<(bool, String)?> evaluate({
    required MicroLesson lesson,
    required String learnerAnswer,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kMicroLessonEvaluationSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Prompt: ${lesson.practicePrompt}\n"
              "Expected correct form: ${lesson.practiceAnswer}\n"
              "Learner's answer: $learnerAnswer",
        },
      ],
      maxTokens: 200,
    );

    final result = _extract(
      reply,
      '<<<EVALUATION>>>',
      '<<<END_EVALUATION>>>',
      (json) => (json['isCorrect'] as bool, json['feedback'] as String),
    );
    return result;
  }

  T? _extract<T>(
    String reply,
    String startMarker,
    String endMarker,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final start = reply.indexOf(startMarker);
    final end = reply.indexOf(endMarker);
    if (start == -1 || end == -1 || end <= start) return null;
    final jsonStr = reply.substring(start + startMarker.length, end).trim();
    try {
      return fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
