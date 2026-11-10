import 'dart:convert';
import 'anthropic_client.dart';
import 'interview_prompts.dart';
import 'interview_models.dart';
import 'teacher_correction_prompts.dart';
import 'chat_message.dart';

class InterviewService {
  Future<InterviewSetup?> generateSetup({
    required JobProfile profile,
    required InterviewType type,
    required InterviewMode mode,
    required int difficultyLevel,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kInterviewSetupSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "${profile.toPromptSummary()}\n"
              "Interview type: ${type.label}\n"
              "Interview mode: ${mode.label}\n"
              "Difficulty (1-6): $difficultyLevel\n"
              "Learner level: $level",
        },
      ],
      maxTokens: 400,
    );

    final start = reply.indexOf('<<<INTERVIEW_SETUP>>>');
    final end = reply.indexOf('<<<END_INTERVIEW_SETUP>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<INTERVIEW_SETUP>>>'.length, end).trim();
    try {
      return InterviewSetup.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Gets the interviewer's next in-character line.
  Future<String> getNextTurn({
    required JobProfile profile,
    required InterviewSetup setup,
    required InterviewType type,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String correctionIntensityKey,
  }) async {
    final intensityDescription =
        kCorrectionIntensityDescriptions[correctionIntensityKey] ??
            kCorrectionIntensityDescriptions['balanced']!;

    final systemPrompt = "$kInterviewEnginePrompt\n\n"
        "${profile.toPromptSummary()}\n"
        "Your role: ${setup.interviewerRole}\n"
        "Interview type: ${type.label}\n"
        "Interview mode: ${mode.label}\n"
        "Focus areas for this interview: ${setup.focusAreas.join('; ')}\n"
        "Correction setting: $correctionIntensityKey — $intensityDescription "
        "(in Mock mode, prefer not to interrupt with corrections; save them for the end-of-interview report)\n"
        "Respond with ONLY your next line as the interviewer — no labels, no stage directions.";

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

  Future<AnswerImprovement?> improveAnswer({
    required String question,
    required String answer,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kAnswerImprovementSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Interview question: \"$question\"\nLearner's answer: \"$answer\"",
        },
      ],
      maxTokens: 500,
    );

    final start = reply.indexOf('<<<ANSWER_IMPROVEMENT>>>');
    final end = reply.indexOf('<<<END_ANSWER_IMPROVEMENT>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr = reply
        .substring(start + '<<<ANSWER_IMPROVEMENT>>>'.length, end)
        .trim();
    try {
      return AnswerImprovement.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<InterviewReport?> getReport({
    required List<ChatMessage> history,
    required JobProfile profile,
  }) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    messages.add({
      "role": "user",
      "content": "TASK: END_INTERVIEW_AND_GIVE_REPORT\n\n${profile.toPromptSummary()}",
    });

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kMockInterviewReportSystemPrompt,
      messages: messages,
      maxTokens: 900,
    );

    final start = reply.indexOf('<<<INTERVIEW_REPORT>>>');
    final end = reply.indexOf('<<<END_INTERVIEW_REPORT>>>');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr =
        reply.substring(start + '<<<INTERVIEW_REPORT>>>'.length, end).trim();
    try {
      return InterviewReport.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
