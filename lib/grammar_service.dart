import 'dart:convert';
import 'anthropic_client.dart';
import 'grammar_prompts.dart';
import 'grammar_models.dart';
import 'local_content.dart';
import 'dart:math';

class GrammarService {
  Future<GrammarDrill?> generateDrill({required String topic, required String level}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kGrammarDrillSystemPrompt,
      messages: [
        {"role": "user", "content": "Topic: $topic\nLearner level: $level"},
      ],
      maxTokens: 300,
    );
    final ai = _extract(reply, '<<<GRAMMAR_DRILL>>>', '<<<END_GRAMMAR_DRILL>>>', GrammarDrill.fromJson);
    return ai ?? _localDrill(topic);
  }

  final Random _random = Random();
  String? _lastLocalPrompt;

  /// Built-in drill so the lab is never empty (no API key / no internet).
  GrammarDrill? _localDrill(String topic) {
    final bank = kLocalGrammarDrills[topic];
    if (bank == null || bank.isEmpty) return null;
    Map<String, Object> pick = bank[_random.nextInt(bank.length)];
    for (var i = 0; i < 4 && bank.length > 1 && pick['prompt'] == _lastLocalPrompt; i++) {
      pick = bank[_random.nextInt(bank.length)];
    }
    _lastLocalPrompt = pick['prompt'] as String;
    return GrammarDrill(
      topic: topic,
      type: pick['type'] as String,
      instruction: pick['instruction'] as String,
      prompt: pick['prompt'] as String,
      hint: pick['hint'] as String,
      acceptedAnswers: List<String>.from(pick['answers'] as List),
      localExplanation: pick['why'] as String,
    );
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<GrammarEvalResult?> evaluate({
    required GrammarDrill drill,
    required String learnerAnswer,
  }) async {
    if (drill.isLocal) {
      final given = _norm(learnerAnswer);
      final ok = drill.acceptedAnswers.any((a) => _norm(a) == given);
      return GrammarEvalResult(
        correct: ok,
        correctAnswer: drill.acceptedAnswers.first,
        explanation: drill.localExplanation,
        encouragement: ok ? 'Well done!' : '',
      );
    }
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
