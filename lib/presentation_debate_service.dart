import 'dart:convert';
import 'anthropic_client.dart';
import 'presentation_debate_prompts.dart';
import 'presentation_debate_models.dart';
import 'chat_message.dart';

class PresentationDebateService {
  Future<PresentationOutline?> getOutline({
    required String topic,
    required String audience,
    required int minutes,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kOutlineSystemPrompt,
      messages: [
        {"role": "user", "content": "Topic: $topic\nAudience: $audience\nDuration: $minutes minutes"},
      ],
      maxTokens: 400,
    );
    return _extract(reply, '<<<PRESENTATION_OUTLINE>>>', '<<<END_PRESENTATION_OUTLINE>>>', PresentationOutline.fromJson);
  }

  Future<String?> getAudienceQuestion({required String presentationText, required List<String> previousQA}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kAudienceQuestionSystemPrompt,
      messages: [
        {
          "role": "user",
          "content": "Presentation: $presentationText\nPrevious Q&A: ${previousQA.join(' | ')}",
        },
      ],
      maxTokens: 150,
    );
    final s = reply.indexOf('<<<AUDIENCE_QUESTION>>>');
    final e = reply.indexOf('<<<END_AUDIENCE_QUESTION>>>');
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      final map = jsonDecode(reply.substring(s + '<<<AUDIENCE_QUESTION>>>'.length, e).trim()) as Map<String, dynamic>;
      return map['question'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<PresentationFeedback?> getPresentationFeedback(List<String> transcript) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kPresentationFeedbackSystemPrompt,
      messages: [
        {"role": "user", "content": transcript.join('\n')},
      ],
      maxTokens: 400,
    );
    return _extract(reply, '<<<PRESENTATION_FEEDBACK>>>', '<<<END_PRESENTATION_FEEDBACK>>>', PresentationFeedback.fromJson);
  }

  Future<String> getDebateOpponentTurn({
    required String topic,
    required String learnerPosition,
    required List<ChatMessage> history,
  }) async {
    final systemPrompt = "$kPresentationEnginePrompt\n\n"
        "Debate topic: $topic\nLearner argues: $learnerPosition. You argue the opposite position, genuinely and respectfully.\n"
        "Respond with ONLY your next argument/counterargument — no labels.";
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    return AnthropicClient.sendMessage(systemPrompt: systemPrompt, messages: messages, maxTokens: 300);
  }

  Future<DebateFeedback?> getDebateFeedback(List<ChatMessage> history) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
    messages.add({"role": "user", "content": "TASK: END_DEBATE_AND_GIVE_FEEDBACK"});
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kDebateFeedbackSystemPrompt,
      messages: messages,
      maxTokens: 400,
    );
    return _extract(reply, '<<<DEBATE_FEEDBACK>>>', '<<<END_DEBATE_FEEDBACK>>>', DebateFeedback.fromJson);
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
