import 'dart:convert';
import 'anthropic_client.dart';
import 'say_it_better_prompts.dart';
import 'say_it_better_result.dart';

const String _startMarker = '<<<SAY_IT_BETTER>>>';
const String _endMarker = '<<<END_SAY_IT_BETTER>>>';

class SayItBetterService {
  Future<SayItBetterResult?> improve(String sentence) async {
    if (sentence.trim().isEmpty) return null;

    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kSayItBetterSystemPrompt,
      messages: [
        {"role": "user", "content": sentence.trim()},
      ],
      maxTokens: 400,
    );

    final start = reply.indexOf(_startMarker);
    final end = reply.indexOf(_endMarker);
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr = reply.substring(start + _startMarker.length, end).trim();
    try {
      return SayItBetterResult.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
