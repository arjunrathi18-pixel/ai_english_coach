import 'dart:convert';
import 'anthropic_client.dart';
import 'orchestrator_prompts.dart';
import 'profile_store.dart';
import 'curriculum_store.dart';
import 'vocabulary_store.dart';

class RouteDecision {
  final String intent;
  final String topic;
  final String reply;
  RouteDecision({required this.intent, required this.topic, required this.reply});
}

class NextBestAction {
  final String intent;
  final String title;
  final String subtitle;
  NextBestAction({required this.intent, required this.title, required this.subtitle});
}

class OrchestratorService {
  /// Understand the learner's message and decide where to go.
  Future<RouteDecision?> route(String userText) async {
    final profile = await ProfileStore.load();
    final context = 'Learner level: ${profile?.overallLevel ?? "unknown"}\nMessage: $userText';
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kOrchestratorPrompt,
      messages: [
        {"role": "user", "content": context},
      ],
      maxTokens: 200,
    );
    const start = '<<<ROUTE>>>';
    const end = '<<<END_ROUTE>>>';
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      final m = jsonDecode(reply.substring(s + start.length, e).trim()) as Map<String, dynamic>;
      return RouteDecision(
        intent: m['intent'] as String,
        topic: m['topic'] as String? ?? '',
        reply: m['reply'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// "Smart Start" / "Surprise me" (Prompt 20 sections 135-136): ONE
  /// primary recommendation from real stored state. No AI call, no
  /// invented history — priority order follows the engine's own
  /// recommendation priority (assessment -> goal -> due review ->
  /// today's challenge).
  Future<NextBestAction> recommendNext() async {
    final profile = await ProfileStore.load();
    if (profile == null) {
      return NextBestAction(
        intent: 'assessment',
        title: 'Find your starting level',
        subtitle: 'A short friendly chat so practice fits you',
      );
    }
    final goal = await CurriculumStore.loadGoal();
    if (goal == null) {
      return NextBestAction(
        intent: 'goal',
        title: 'Choose your learning goal',
        subtitle: 'So your practice has a direction',
      );
    }
    final due = await VocabularyStore.dueForReview(limit: 5);
    if (due.isNotEmpty) {
      return NextBestAction(
        intent: 'review',
        title: 'Quick review',
        subtitle: '${due.length} word${due.length == 1 ? '' : 's'} ready to review',
      );
    }
    return NextBestAction(
      intent: 'daily_challenge',
      title: "Today's challenge",
      subtitle: 'A practice picked for your level and goal',
    );
  }
}
