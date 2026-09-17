import 'dart:convert';

import 'anthropic_client.dart';
import 'learning_engine_prompts.dart';
import 'learner_profile.dart';
import 'learning_goal.dart';
import 'curriculum.dart';
import 'daily_session.dart';

/// Drives the Personalized Learning Engine (Prompt 3). Unlike the tutor
/// conversation and the assessment, these calls are single-shot request/
/// response — no back-and-forth chat history needed, just structured
/// input in, structured plan out.
class LearningEngineService {
  Future<LearningRoadmap?> generateRoadmap({
    required LearnerProfile profile,
    required GoalSelection goal,
  }) async {
    final task = """
TASK: GENERATE_ROADMAP

LEARNER PROFILE:
${jsonEncode(profile.toJson())}

GOAL SELECTION:
${jsonEncode(goal.toJson())}
""";

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kLearningEngineSystemPrompt,
      messages: [
        {"role": "user", "content": task},
      ],
      maxTokens: 900,
    );

    return _extractBlock<LearningRoadmap>(
      reply,
      '<<<ROADMAP>>>',
      '<<<END_ROADMAP>>>',
      LearningRoadmap.fromJson,
    );
  }

  Future<DailySessionPlan?> generateDailySession({
    required LearnerProfile profile,
    required LearningRoadmap roadmap,
    required List<RecurringMistake> recentMistakes,
    required int availableMinutesToday,
  }) async {
    final currentWeek = roadmap.weeks.isNotEmpty ? roadmap.weeks.first : null;

    final task = """
TASK: GENERATE_DAILY_SESSION

LEARNER PROFILE:
${jsonEncode(profile.toJson())}

ROADMAP:
${jsonEncode(roadmap.toJson())}

CURRENT WEEK FOCUS:
${currentWeek != null ? jsonEncode(currentWeek.toJson()) : "none"}

RECENT RECURRING MISTAKES:
${jsonEncode(recentMistakes.map((m) => m.toJson()).toList())}

AVAILABLE MINUTES TODAY: $availableMinutesToday
""";

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kLearningEngineSystemPrompt,
      messages: [
        {"role": "user", "content": task},
      ],
      maxTokens: 700,
    );

    return _extractBlock<DailySessionPlan>(
      reply,
      '<<<DAILY_SESSION>>>',
      '<<<END_DAILY_SESSION>>>',
      DailySessionPlan.fromJson,
    );
  }

  T? _extractBlock<T>(
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
