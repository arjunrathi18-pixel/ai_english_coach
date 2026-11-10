import 'dart:convert';
import 'anthropic_client.dart';
import 'daily_challenge_prompts.dart';
import 'daily_challenge_models.dart';
import 'curriculum_store.dart';
import 'profile_store.dart';
import 'learning_goal.dart';

class DailyChallengeService {
  Future<DailyChallenge?> generate({required int minutes}) async {
    final profile = await ProfileStore.load();
    final goal = await CurriculumStore.loadGoal();
    final mistakes = await CurriculumStore.loadMistakes();
    final top = ([...mistakes]..sort((a, b) => b.timesObserved.compareTo(a.timesObserved)))
        .take(3)
        .map((m) => m.pattern)
        .join('; ');

    final context = StringBuffer()
      ..writeln('Available time: $minutes minutes')
      ..writeln('Level: ${profile?.overallLevel ?? "unknown"}')
      ..writeln('Goal: ${goal == null ? "not set" : goal.primaryGoal.label}')
      ..writeln('Recent recurring mistakes: ${top.isEmpty ? "none tracked" : top}');

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kDailyChallengePrompt,
      messages: [
        {"role": "user", "content": context.toString()},
      ],
      maxTokens: 500,
    );
    const start = '<<<DAILY_CHALLENGE>>>';
    const end = '<<<END_DAILY_CHALLENGE>>>';
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      return DailyChallenge.fromJson(
          jsonDecode(reply.substring(s + start.length, e).trim()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
