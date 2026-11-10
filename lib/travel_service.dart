import 'dart:convert';
import 'anthropic_client.dart';
import 'travel_prompts.dart';

class TravelPhrase {
  final String phrase;
  final String whenToUse;
  TravelPhrase({required this.phrase, required this.whenToUse});
}

class TravelKit {
  final String situation;
  final List<TravelPhrase> phrases;
  final List<String> listenFor;
  final String tip;
  TravelKit({required this.situation, required this.phrases, required this.listenFor, required this.tip});

  factory TravelKit.fromJson(Map<String, dynamic> json) => TravelKit(
        situation: json['situation'] as String,
        phrases: (json['phrases'] as List? ?? [])
            .map((p) => TravelPhrase(
                  phrase: (p as Map<String, dynamic>)['phrase'] as String,
                  whenToUse: p['whenToUse'] as String? ?? '',
                ))
            .toList(),
        listenFor: List<String>.from(json['listenFor'] as List? ?? []),
        tip: json['tip'] as String? ?? '',
      );
}

class TravelService {
  Future<TravelKit?> buildKit({required String situation, required String level}) async {
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: kTravelKitPrompt,
      messages: [
        {"role": "user", "content": "Situation: $situation\nLearner level: $level"},
      ],
      maxTokens: 700,
    );
    const start = '<<<TRAVEL_KIT>>>';
    const end = '<<<END_TRAVEL_KIT>>>';
    final s = reply.indexOf(start);
    final e = reply.indexOf(end);
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      return TravelKit.fromJson(jsonDecode(reply.substring(s + start.length, e).trim()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
