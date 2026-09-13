import 'anthropic_client.dart';
import 'system_prompts.dart';
import 'chat_message.dart';
import 'session_settings.dart';

/// Handles the everyday tutor conversation (Friend/Tutor/Coach modes).
/// Talks to the model through the shared AnthropicClient, using the
/// Master Brain prompt (Prompt 1) plus the current session settings.
class AiTutorService {
  Future<String> getNextReply({
    required List<ChatMessage> history,
    required SessionSettings settings,
  }) async {
    final systemPrompt = kMasterBrainPrompt +
        "\n\n" +
        buildSessionContextPrompt(
          mode: settings.mode,
          correctionMode: settings.correctionMode,
          estimatedLevel: settings.estimatedLevel,
          accent: settings.accent,
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
