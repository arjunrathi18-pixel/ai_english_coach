import 'dart:convert';
import 'anthropic_client.dart';
import 'fluency_prompts.dart';
import 'fluency_models.dart';

class FluencyService {
  Future<String?> getRapidQuestion(String level) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kRapidQuestionSystemPrompt,
      messages: [
        {"role": "user", "content": "Learner level: $level"},
      ],
      maxTokens: 150,
    );
    final map = _extractRaw(reply, '<<<RAPID_QUESTION>>>', '<<<END_RAPID_QUESTION>>>');
    return map?['question'] as String?;
  }

  Future<String?> getRapidFeedback({
    required String question,
    required String answer,
    required int elapsedSeconds,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kRapidFeedbackSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Question: $question\nAnswer: $answer\nMeasured response time: ${elapsedSeconds}s",
        },
      ],
      maxTokens: 200,
    );
    final map = _extractRaw(reply, '<<<RAPID_FEEDBACK>>>', '<<<END_RAPID_FEEDBACK>>>');
    return map?['feedback'] as String?;
  }

  Future<String?> getSpeakingTopic(String level) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kSpeakingTopicSystemPrompt,
      messages: [
        {"role": "user", "content": "Learner level: $level"},
      ],
      maxTokens: 150,
    );
    final map = _extractRaw(reply, '<<<SPEAKING_TOPIC>>>', '<<<END_SPEAKING_TOPIC>>>');
    return map?['topic'] as String?;
  }

  Future<OneMinuteFeedback?> getOneMinuteFeedback({required String topic, required String response}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kOneMinuteFeedbackSystemPrompt,
      messages: [
        {"role": "user", "content": "Topic: $topic\nLearner's response: $response"},
      ],
      maxTokens: 300,
    );
    return _extract(reply, '<<<ONE_MINUTE_FEEDBACK>>>', '<<<END_ONE_MINUTE_FEEDBACK>>>', OneMinuteFeedback.fromJson);
  }

  Future<String?> getCircumlocutionTarget(String level) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kCircumlocutionTargetSystemPrompt,
      messages: [
        {"role": "user", "content": "Learner level: $level"},
      ],
      maxTokens: 100,
    );
    final map = _extractRaw(reply, '<<<CIRCUMLOCUTION_TARGET>>>', '<<<END_CIRCUMLOCUTION_TARGET>>>');
    return map?['word'] as String?;
  }

  Future<CircumlocutionEval?> evaluateCircumlocution({required String target, required String description}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kCircumlocutionEvalSystemPrompt,
      messages: [
        {"role": "user", "content": "Secret target word: $target\nLearner's description: $description"},
      ],
      maxTokens: 200,
    );
    return _extract(reply, '<<<CIRCUMLOCUTION_EVAL>>>', '<<<END_CIRCUMLOCUTION_EVAL>>>', CircumlocutionEval.fromJson);
  }

  Map<String, dynamic>? _extractRaw(String reply, String start, String end) {
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      return jsonDecode(reply.substring(s + start.length, e).trim()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  T? _extract<T>(String reply, String start, String end, T Function(Map<String, dynamic>) fromJson) {
    final map = _extractRaw(reply, start, end);
    if (map == null) return null;
    try {
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
