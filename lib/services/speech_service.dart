import 'package:flutter_tts/flutter_tts.dart';

import 'recognition_result.dart';

/// Wraps voice input (speech-to-text) and voice output (text-to-speech).
///
/// TEMPORARY STATUS: mic-based voice input is disabled for now — the
/// `speech_to_text` plugin has an unresolved Android Gradle/compileSdk
/// compatibility issue with current tooling that was blocking APK builds
/// entirely (a plugin-ecosystem issue, not something wrong in this app's
/// own code). Voice OUTPUT (text-to-speech) is unaffected and works
/// normally. Every screen that uses the mic already checks
/// `isAvailable`/`init()` and falls back to text input gracefully, so
/// disabling this here doesn't crash anything — it just means the mic
/// button shows a "not available" message until this is re-enabled.
///
/// TO RE-ENABLE LATER: add `speech_to_text` back to pubspec.yaml (try a
/// specific pinned version rather than a caret range), restore the
/// `stt.SpeechToText` implementation below, and remove this notice.
class SpeechService {
  final FlutterTts _tts = FlutterTts();

  Future<bool> init() async {
    await _tts.setSpeechRate(0.45); // slightly slower for learners
    await _tts.setPitch(1.0);
    return false; // mic input temporarily disabled — see class doc above
  }

  bool get isAvailable => false;

  Future<void> startListening({
    required void Function(String recognizedWords) onResult,
  }) async {
    // No-op: voice input temporarily disabled. Screens should check
    // isAvailable/init() before calling this and show text input instead.
  }

  Future<void> startListeningDetailed({
    required void Function(RecognitionResult result) onResult,
  }) async {
    onResult(RecognitionResult.unavailable());
  }

  Future<void> stopListening() async {}

  bool get isListening => false;

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

  /// Sets TTS speaking rate for listening practice (Prompt 8, section 24).
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
