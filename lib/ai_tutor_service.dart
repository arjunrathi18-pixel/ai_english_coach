import 'anthropic_client.dart';
import 'system_prompts.dart';
import 'friend_mode_prompts.dart';
import 'teacher_correction_prompts.dart';
import 'vocabulary_prompts.dart';
import 'chat_message.dart';
import 'session_settings.dart';
import 'correction_intensity.dart';
import 'ai_personality.dart';
import 'conversation_length.dart';

/// Handles the everyday tutor conversation (Friend/Tutor/Coach modes).
/// Talks to the model through the shared AnthropicClient, using:
///  - Master Brain (Prompt 1) — always
///  - Friend Mode engine (Prompt 4) — only when mode == 'friend'
///  - Teacher & Correction engine (Prompt 5) — always
///  - Vocabulary & Natural Expression awareness (Prompt 7) — always
class AiTutorService {
  String _buildSystemPrompt(SessionSettings settings) {
    final modeSpecificPrompt =
        settings.mode == 'friend' ? "\n\n$kFriendModePrompt" : "";

    final intensityKey = settings.correctionIntensity.key;
    final intensityDescription =
        kCorrectionIntensityDescriptions[intensityKey] ??
            kCorrectionIntensityDescriptions['balanced']!;

    return kMasterBrainPrompt +
        modeSpecificPrompt +
        "\n\n$kTeacherCorrectionPrompt" +
        "\n\n$kVocabularyConversationPrompt" +
        "\n\n" +
        buildSessionContextPrompt(
          mode: settings.mode,
          correctionIntensity: settings.correctionIntensity.label,
          correctionIntensityDescription: intensityDescription,
          estimatedLevel: settings.estimatedLevel,
          accent: settings.accent,
          sessionFocus: settings.sessionFocus,
          personalityLabel: settings.personality.label,
          conversationLengthLabel: settings.conversationLength.label,
        );
  }

  /// The Messages API requires the first message to be from the user, but
  /// our chat opens with the coach's greeting — so drop any leading AI
  /// messages (the system prompt already carries the context).
  List<Map<String, String>> _toMessages(List<ChatMessage> history) {
    final firstUser = history.indexWhere((m) => m.sender == SenderType.user);
    final usable = firstUser == -1 ? <ChatMessage>[] : history.sublist(firstUser);
    return usable
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();
  }

  Future<String> getNextReply({
    required List<ChatMessage> history,
    required SessionSettings settings,
  }) {
    return AnthropicClient.sendMessage(
      systemPrompt: _buildSystemPrompt(settings),
      messages: _toMessages(history),
      maxTokens: 500,
    );
  }

  /// Streams the reply as it is written, so the app can show text and start
  /// speaking after the first sentence instead of waiting for the whole answer.
  Stream<String> streamNextReply({
    required List<ChatMessage> history,
    required SessionSettings settings,
  }) {
    return AnthropicClient.streamMessage(
      systemPrompt: _buildSystemPrompt(settings),
      messages: _toMessages(history),
      maxTokens: 320,
    );
  }
}
