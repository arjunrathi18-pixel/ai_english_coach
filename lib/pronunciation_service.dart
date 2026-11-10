import 'dart:convert';
import 'anthropic_client.dart';
import 'pronunciation_prompts.dart';
import 'pronunciation_models.dart';

class PronunciationService {
  Future<PhoneticInfo?> getPhoneticInfo({
    required String word,
    required String accent,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt:
          "$kPronunciationCoachPrompt\n\n$kPhoneticInfoOutputContract",
      messages: [
        {
          "role": "user",
          "content":
              "Target word: \"$word\"\nPreferred accent: $accent\nLearner level: $level",
        },
      ],
      maxTokens: 300,
    );
    return _extract(reply, '<<<PHONETIC_INFO>>>', '<<<END_PHONETIC_INFO>>>',
        PhoneticInfo.fromJson);
  }

  Future<ShadowingFeedback?> getShadowingFeedback({
    required String targetSentence,
    required String recognizedText,
    required double confidence,
    required List<String> alternates,
    required bool audioAvailable,
    required String accent,
    required String level,
  }) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt:
          "$kPronunciationCoachPrompt\n\n$kShadowingFeedbackOutputContract",
      messages: [
        {
          "role": "user",
          "content": "OBSERVED DATA ONLY:\n"
              "Target sentence: \"$targetSentence\"\n"
              "Recognized speech: \"$recognizedText\"\n"
              "Recognition confidence: $confidence\n"
              "Recognition alternates: ${alternates.isEmpty ? 'none' : alternates.join(' | ')}\n"
              "Audio available: $audioAvailable\n"
              "Preferred accent: $accent\n"
              "Learner level: $level",
        },
      ],
      maxTokens: 300,
    );
    return _extract(
      reply,
      '<<<SHADOWING_FEEDBACK>>>',
      '<<<END_SHADOWING_FEEDBACK>>>',
      ShadowingFeedback.fromJson,
    );
  }

  Future<MinimalPairSet?> getMinimalPairs(String soundDescription) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt:
          "$kPronunciationCoachPrompt\n\n$kMinimalPairsOutputContract",
      messages: [
        {"role": "user", "content": "Trouble sound: $soundDescription"},
      ],
      maxTokens: 300,
    );
    return _extract(reply, '<<<MINIMAL_PAIRS>>>', '<<<END_MINIMAL_PAIRS>>>',
        MinimalPairSet.fromJson);
  }

  T? _extract<T>(
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
