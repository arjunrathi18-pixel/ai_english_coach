import 'dart:convert';
import 'anthropic_client.dart';
import 'grammar_prompts.dart';
import 'grammar_models.dart';

class GrammarService {
  Future<GrammarDrill?> generateDrill({required String topic, required String level}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kGrammarDrillSystemPrompt,
      messages: [
        {"role": "user", "content": "Topic: $topic\nLearner level: $level"},
      ],
      maxTokens: 300,
    );
    return _extract(reply, '<<<GRAMMAR_DRILL>>>', '<<<END_GRAMMAR_DRILL>>>', GrammarDrill.fromJson);
  }

  Future<GrammarEvalResult?> evaluate({
    required GrammarDrill drill,
    required String learnerAnswer,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kGrammarEvalSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Topic: ${drill.topic}\nPrompt: ${drill.prompt}\nLearner's answer: $learnerAnswer",
        },
      ],
      maxTokens: 250,
    );
    return _extract(reply, '<<<GRAMMAR_EVAL>>>', '<<<END_GRAMMAR_EVAL>>>', GrammarEvalResult.fromJson);
  }

  T? _extract<T>(String reply, String start, String end, T Function(Map<String, dynamic>) fromJson) {
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    final jsonStr = reply.substring(s + start.length, e).trim();
    try {
      return fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
