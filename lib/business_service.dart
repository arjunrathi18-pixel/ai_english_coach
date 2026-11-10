import 'dart:convert';
import 'anthropic_client.dart';
import 'business_prompts.dart';
import 'business_models.dart';
import 'chat_message.dart';

class BusinessService {
  Future<MeetingSetup?> setupMeeting({
    required String topic,
    required String learnerRole,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kMeetingSetupSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Meeting topic: $topic\nLearner's role: $learnerRole\nLearner level: $level",
        },
      ],
      maxTokens: 350,
    );
    return _extract(reply, '<<<MEETING_SETUP>>>', '<<<END_MEETING_SETUP>>>', MeetingSetup.fromJson);
  }

  Future<String> getMeetingTurn({
    required MeetingSetup setup,
    required String topic,
    required List<ChatMessage> history,
  }) async {
    final systemPrompt = "$kBusinessEnginePrompt\n\n"
        "You are: ${setup.counterpartRole}\nMeeting topic: $topic\n"
        "Agenda: ${setup.agendaItems.join('; ')}\n"
        "Respond with ONLY your next in-character line — no labels.";
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    return AnthropicClient.sendMessage(systemPrompt: systemPrompt, messages: messages, maxTokens: 300);
  }

  Future<MeetingSummary?> getMeetingSummary(List<ChatMessage> history) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    messages.add({"role": "user", "content": "TASK: END_MEETING_AND_SUMMARIZE"});
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kMeetingSummarySystemPrompt,
      messages: messages,
      maxTokens: 600,
    );
    return _extract(reply, '<<<MEETING_SUMMARY>>>', '<<<END_MEETING_SUMMARY>>>', MeetingSummary.fromJson);
  }

  Future<EmailDraft?> draftEmail({
    required String purpose,
    required String keyPoints,
    required String register,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kEmailDraftSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Purpose: $purpose\nKey points: $keyPoints\nRegister: $register",
        },
      ],
      maxTokens: 500,
    );
    return _extract(reply, '<<<EMAIL_DRAFT>>>', '<<<END_EMAIL_DRAFT>>>', EmailDraft.fromJson);
  }

  Future<EmailCritique?> critiqueEmail(String draft) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kEmailCritiqueSystemPrompt,
      messages: [
        {"role": "user", "content": "Learner's draft:\n$draft"},
      ],
      maxTokens: 500,
    );
    return _extract(reply, '<<<EMAIL_CRITIQUE>>>', '<<<END_EMAIL_CRITIQUE>>>', EmailCritique.fromJson);
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
