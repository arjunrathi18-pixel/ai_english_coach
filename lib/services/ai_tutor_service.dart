import 'anthropic_client.dart';
import 'system_prompts.dart';
import 'friend_mode_prompts.dart';
import 'teacher_correction_prompts.dart';
import 'vocabulary_prompts.dart';
import 'chat_message.dart';
import 'session_settings.dart';

/// Handles the everyday tutor conversation (Friend/Tutor/Coach modes).
/// Talks to the model through the shared AnthropicClient, using:
///  - Master Brain (Prompt 1) — always
///  - Friend Mode engine (Prompt 4) — only when mode == 'friend'
///  - Teacher & Correction engine (Prompt 5) — always
///  - Vocabulary & Natural Expression awareness (Prompt 7) — always
class AiTutorService {
  Future<String> getNextReply({
    required List<ChatMessage> history,
    required SessionSettings settings,
  }) async {
    final modeSpecificPrompt =
        settings.mode == 'friend' ? "\n\n$kFriendModePrompt" : "";

    final intensityKey = settings.correctionIntensity.key;
    final intensityDescription =
        kCorrectionIntensityDescriptions[intensityKey] ??
            kCorrectionIntensityDescriptions['balanced']!;

    final systemPrompt = kMasterBrainPrompt +
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

    final messages = history
        .map((m) => {
              "role": m.sender == SenderType.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    return AnthropicClient.sendMessage(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: 500,
    );
  }
}
