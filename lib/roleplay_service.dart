import 'dart:convert';
import 'anthropic_client.dart';
import 'roleplay_prompts.dart';
import 'roleplay_models.dart';
import 'teacher_correction_prompts.dart';
import 'chat_message.dart';

class RoleplayService {
  Future<RoleplayScenario?> generateScenario({
    required String request, // e.g. "Sales > Handling a price objection" or free text
    required String level,
    required String goal,
    required int difficultyLevel,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kRoleplayScenarioSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Scenario request: \"$request\"\n"
              "Learner level: $level\n"
              "Learner goal: $goal\n"
              "Requested difficulty (1-6): $difficultyLevel",
        },
      ],
      maxTokens: 500,
    );

    final start = reply.indexOf('<<<ROLEPLAY_SCENARIO>>>');
    final end = reply.indexOf('<<<END_ROLEPLAY_SCENARIO>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<ROLEPLAY_SCENARIO>>>'.length, end).trim();
    try {
      return RoleplayScenario.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Gets the AI character's next in-character line. [history] should NOT
  /// include the scenario's opening line as a synthetic system message —
  /// pass it as the first ChatMessage(sender: ai) instead, like any other
  /// turn, so the model sees a normal conversation.
  Future<String> getNextTurn({
    required RoleplayScenario scenario,
    required List<ChatMessage> history,
    required String correctionIntensityKey,
  }) async {
    final intensityDescription =
        kCorrectionIntensityDescriptions[correctionIntensityKey] ??
            kCorrectionIntensityDescriptions['balanced']!;

    final systemPrompt = "$kRoleplayEnginePrompt\n\n"
        "${scenario.toSystemContext()}\n\n"
        "Correction setting for this session: $correctionIntensityKey — $intensityDescription\n"
        "Respond with ONLY your character's next line — no labels, no stage directions, just what they'd say.";

    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    return AnthropicClient.sendMessage(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: 300,
    );
  }

  Future<RoleplayFeedback?> getFeedback({
    required RoleplayScenario scenario,
    required List<ChatMessage> history,
  }) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    messages.add({
      "role": "user",
      "content": "TASK: END_ROLEPLAY_AND_GIVE_FEEDBACK\n\n"
          "Scenario: ${scenario.title}\nLearner's objective was: ${scenario.objective}",
    });

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kRoleplayFeedbackSystemPrompt,
      messages: messages,
      maxTokens: 400,
    );

    final start = reply.indexOf('<<<ROLEPLAY_FEEDBACK>>>');
    final end = reply.indexOf('<<<END_ROLEPLAY_FEEDBACK>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<ROLEPLAY_FEEDBACK>>>'.length, end).trim();
    try {
      return RoleplayFeedback.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
