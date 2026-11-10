import 'dart:convert';

import 'anthropic_client.dart';
import 'friend_mode_prompts.dart';
import 'system_prompts.dart';
import 'chat_message.dart';
import 'conversation_summary.dart';
import 'curriculum.dart';
import 'curriculum_store.dart';

const String _startMarker = '<<<CONVERSATION_SUMMARY>>>';
const String _endMarker = '<<<END_CONVERSATION_SUMMARY>>>';

class ConversationSummaryService {
  /// Asks the model to close out the conversation with structured
  /// end-of-session feedback (Prompt 4, sections 37-38).
  Future<ConversationSummary?> getSummary(List<ChatMessage> history) async {
    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    messages.add({
      "role": "user",
      "content": "TASK: END_OF_CONVERSATION_SUMMARY",
    });

    final systemPrompt =
        "$kMasterBrainPrompt\n\n$kFriendModePrompt\n\n$kConversationSummaryOutputContract";

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: 600,
    );

    final start = reply.indexOf(_startMarker);
    final end = reply.indexOf(_endMarker);
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr = reply.substring(start + _startMarker.length, end).trim();
    try {
      return ConversationSummary.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Merges this session's recurring-mistake observations into the
  /// persisted mistake list used by the Personalized Learning Engine
  /// (Prompt 3) — bumping the count if a similar pattern already exists,
  /// otherwise adding it as new.
  Future<void> saveRecurringMistakes(List<String> newPatterns) async {
    if (newPatterns.isEmpty) return;
    final existing = await CurriculumStore.loadMistakes();

    for (final pattern in newPatterns) {
      final index = existing.indexWhere(
        (m) => m.pattern.toLowerCase() == pattern.toLowerCase(),
      );
      if (index >= 0) {
        final old = existing[index];
        existing[index] = RecurringMistake(
          pattern: old.pattern,
          timesObserved: old.timesObserved + 1,
          lastObserved: DateTime.now(),
        );
      } else {
        existing.add(RecurringMistake(pattern: pattern, timesObserved: 1));
      }
    }

    await CurriculumStore.saveMistakes(existing);
  }
}
