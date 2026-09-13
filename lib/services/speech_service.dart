import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps voice input (speech-to-text) and voice output (text-to-speech)
/// behind one simple interface. Screens should never talk to the
/// speech_to_text / flutter_tts packages directly.
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

  /// Starts listening. [onResult] fires with partial + final transcripts.
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
