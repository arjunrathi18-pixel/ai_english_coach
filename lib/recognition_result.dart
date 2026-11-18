/// The complete set of "observed data" the speech recognizer actually
/// provides for one listening attempt — see Prompt 6's technical honesty
/// contract. Nothing in this class is inferred or measured beyond what
/// the on-device recognizer itself returns.
class RecognitionResult {
  final String transcript;
  final double confidence; // 0.0-1.0; recognizer's own confidence
  final List<String> alternates; // other things it considered hearing
  final bool isFinal;
  final bool audioAvailable; // false if mic/recognizer never engaged

  RecognitionResult({
    required this.transcript,
    required this.confidence,
    required this.alternates,
    required this.isFinal,
    required this.audioAvailable,
  });

  /// Used when speech recognition couldn't run at all (no permission,
  /// not initialized, etc.) — audioAvailable is false so downstream
  /// pronunciation features know not to attempt feedback.
  factory RecognitionResult.unavailable() => RecognitionResult(
        transcript: '',
        confidence: 0.0,
        alternates: const [],
        isFinal: true,
        audioAvailable: false,
      );

  /// A conservative, honest check for whether this result is worth
  /// sending to the pronunciation engine at all — matches the "audio
  /// quality check" step in the honesty contract.
  bool get looksReliable =>
      audioAvailable && transcript.trim().isNotEmpty && confidence >= 0.4;
}
