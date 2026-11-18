import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'recognition_result.dart';

/// Wraps voice input (speech-to-text) and voice output (text-to-speech)
/// behind one simple interface. Screens never talk to the speech_to_text /
/// flutter_tts packages directly.
///
/// Per Prompt 6's honesty contract, this service is the single source of
/// "observed data" for pronunciation features: transcript, confidence,
/// alternatives, and whether audio was captured at all. It never invents
/// acoustic measurements the underlying plugin doesn't actually provide.
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  bool _ttsReady = false;
  String _accent = 'indian';
  double _rate = 0.5;

  Future<bool> init() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    await _prepareTts();
    return _speechEnabled;
  }

  Future<void> _prepareTts() async {
    if (_ttsReady) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(_rate);
      // Prefer Google's engine (best quality voices on most Android phones).
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
      await setAccent(_accent);
    } catch (_) {
      // TTS setup is best-effort; speaking still works with the default voice.
    }
    _ttsReady = true;
  }

  bool get isAvailable => _speechEnabled;

  String get _localeId {
    switch (_accent) {
      case 'american':
        return 'en_US';
      case 'british':
        return 'en_GB';
      default:
        return 'en_IN';
    }
  }

  /// Simple listening for ordinary conversation — just the recognized text.
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

  /// Hands-off listening for voice chat: [onPartial] fires while the
  /// learner speaks, and [onFinal] fires ONCE when they stop talking —
  /// so the message can be sent automatically without tapping again.
  Future<void> startListeningAuto({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
  }) async {
    if (!_speechEnabled) return;
    var delivered = false;
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (delivered) return;
          delivered = true;
          onFinal(result.recognizedWords);
        } else {
          onPartial(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(milliseconds: 2200),
      partialResults: true,
      localeId: _localeId,
      cancelOnError: false,
    );
  }

  /// Richer listening for pronunciation features (shadowing, word
  /// practice): surfaces every piece of "observed data" the recognizer
  /// actually provides — transcript, confidence, alternates.
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

  /// Sets TTS language and picks the best installed voice for the chosen
  /// English variety (network/neural voices sound far more natural than
  /// the default compact one).
  Future<void> setAccent(String accent) async {
    _accent = accent;
    final locale = accent == 'american' ? 'en-US' : (accent == 'british' ? 'en-GB' : 'en-IN');
    try {
      await _tts.setLanguage(locale);
      await _pickBestVoice(locale);
    } catch (_) {}
  }

  Future<void> _pickBestVoice(String locale) async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final v in voices) {
      if (v is! Map) continue;
      final name = (v['name'] ?? '').toString();
      final loc = (v['locale'] ?? '').toString().replaceAll('_', '-').toLowerCase();
      if (loc != locale.toLowerCase()) continue;
      final lower = name.toLowerCase();
      var score = 1;
      if (lower.contains('network')) score += 4;
      if (lower.contains('neural') || lower.contains('wavenet')) score += 4;
      if (lower.contains('enhanced') || lower.contains('premium')) score += 2;
      if (lower.contains('local') && !lower.contains('network')) score -= 1;
      if (score > bestScore) {
        bestScore = score;
        best = {'name': name, 'locale': (v['locale'] ?? locale).toString()};
      }
    }
    if (best != null) {
      await _tts.setVoice({'name': best['name'] as String, 'locale': best['locale'] as String});
    }
  }

  /// Removes things a voice should never read out loud: markdown symbols,
  /// emojis, response markers and links — a big reason robot voices sound bad.
  static String cleanForSpeech(String input) {
    var t = input;
    t = t.replaceAll(RegExp(r'<<<[^>]*>>>'), ' ');
    t = t.replaceAll(RegExp(r'https?://\S+'), ' ');
    t = t.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'[*_#>`~|]+'), '');
    t = t.replaceAll('—', ', ').replaceAll('–', ', ');
    t = t.replaceAll(RegExp(r'\s*\n+\s*'), '. ');
    t = t.replaceAll(RegExp(r'\.\s*\.'), '.');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t.trim();
  }

  /// Speaks right away, interrupting anything already playing.
  Future<void> speak(String text) async {
    await _prepareTts();
    final clean = cleanForSpeech(text);
    if (clean.isEmpty) return;
    await _tts.stop();
    await _tts.speak(clean);
  }

  /// Speaks after whatever is already playing (does not interrupt).
  /// Used to read a streamed reply sentence by sentence.
  Future<void> speakQueued(String text) async {
    await _prepareTts();
    final clean = cleanForSpeech(text);
    if (clean.isEmpty) return;
    await _tts.speak(clean);
  }

  /// Sets TTS speaking rate (listening practice and learner preference).
  Future<void> setSpeechRate(double rate) async {
    _rate = rate;
    await _tts.setSpeechRate(rate);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
