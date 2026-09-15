import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'recognition_result.dart';

/// Wraps voice input (speech-to-text) and voice output (text-to-speech)
/// behind one simple interface. Screens should never talk to the
/// speech_to_text / flutter_tts packages directly.
///
/// Per Prompt 6's honesty contract, this service is the single source of
/// "observed data" for pronunciation features: transcript, confidence,
/// alternatives, and whether audio was captured at all. It never invents
/// acoustic measurements the underlying plugin doesn't actually provide.
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;

  Future<bool> init() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    await _tts.setSpeechRate(0.45); // slightly slower for learners
    await _tts.setPitch(1.0);
    return _speechEnabled;
  }

  bool get isAvailable => _speechEnabled;

  /// Simple listening for ordinary conversation (chat_screen.dart) — just
  /// the recognized text, no observed-data detail needed there.
  Future<void> startListening({
    required void Function(String recognizedWords) onResult,
  }) async {
    if (!_speechEnabled) return;
    await _speechToText.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  /// Richer listening for pronunciation features (shadowing, word
  /// practice): surfaces every piece of "observed data" the recognizer
  /// actually provides — transcript, confidence, alternates — so the
  /// pronunciation engine can reason honestly instead of guessing.
  Future<void> startListeningDetailed({
    required void Function(RecognitionResult result) onResult,
  }) async {
    if (!_speechEnabled) {
      onResult(RecognitionResult.unavailable());
      return;
    }
    await _speechToText.listen(
      onResult: (result) {
        onResult(RecognitionResult(
          transcript: result.recognizedWords,
          confidence: result.confidence,
          alternates: result.alternates
              .map((a) => a.recognizedWords)
              .where((w) => w.isNotEmpty)
              .toList(),
          isFinal: result.finalResult,
          audioAvailable: true,
        ));
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;

  /// Sets TTS voice/locale based on the selected English variety.
  /// Actual voice availability depends on the device's installed TTS voices.
  Future<void> setAccent(String accent) async {
    switch (accent) {
      case 'american':
        await _tts.setLanguage('en-US');
        break;
      case 'british':
        await _tts.setLanguage('en-GB');
        break;
      case 'indian':
      default:
        await _tts.setLanguage('en-IN');
        break;
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
