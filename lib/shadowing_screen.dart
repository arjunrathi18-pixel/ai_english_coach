import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'recognition_result.dart';
import 'pronunciation_service.dart';
import 'pronunciation_models.dart';
import 'profile_store.dart';

/// A small built-in set of practice sentences at increasing difficulty
/// (Prompt 6, section 35 — progressive repetition difficulty). A future
/// version could pull these from the Personalized Learning Engine instead.
const List<String> _kShadowingSentences = [
  "I usually wake up early.",
  "Could you send me the report by Friday?",
  "I'd like to discuss the project with you.",
  "Honestly, I wasn't expecting that at all.",
  "What would you do if you had an extra day off every week?",
];

class ShadowingScreen extends StatefulWidget {
  const ShadowingScreen({super.key});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  final SpeechService _speech = SpeechService();
  final PronunciationService _pronunciation = PronunciationService();

  int _sentenceIndex = 0;
  bool _isListening = false;
  bool _isChecking = false;
  RecognitionResult? _lastResult;
  ShadowingFeedback? _feedback;
  String _accent = 'indian';
  String _level = 'unknown';

  String get _targetSentence => _kShadowingSentences[_sentenceIndex];

  @override
  void initState() {
    super.initState();
    _speech.init();
    _loadLearnerContext();
  }

  Future<void> _loadLearnerContext() async {
    final profile = await ProfileStore.load();
    if (profile != null) {
      setState(() => _level = profile.overallLevel);
    }
  }

  Future<void> _playTarget() async {
    await _speech.setAccent(_accent);
    await _speech.speak(_targetSentence);
  }

  Future<void> _record() async {
    if (!_speech.isAvailable) {
      final ok = await _speech.init();
      if (!ok) return;
    }
    setState(() {
      _isListening = true;
      _feedback = null;
    });
    await _speech.startListeningDetailed(
      onResult: (result) => setState(() => _lastResult = result),
    );
  }

  Future<void> _stopAndCheck() async {
    await _speech.stopListening();
    setState(() => _isListening = false);

    final result = _lastResult;
    if (result == null) return;

    setState(() => _isChecking = true);
    final feedback = await _pronunciation.getShadowingFeedback(
      targetSentence: _targetSentence,
      recognizedText: result.transcript,
      confidence: result.confidence,
      alternates: result.alternates,
      audioAvailable: result.audioAvailable,
      accent: _accent,
      level: _level,
    );
    setState(() {
      _feedback = feedback;
      _isChecking = false;
    });
  }

  void _nextSentence() {
    setState(() {
      _sentenceIndex = (_sentenceIndex + 1) % _kShadowingSentences.length;
      _lastResult = null;
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shadowing Practice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentence ${_sentenceIndex + 1} of ${_kShadowingSentences.length}',
                style: const TextStyle(color: Colors.black45)),
            const SizedBox(height: 8),
            Text(_targetSentence,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _playTarget,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Listen'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isListening ? _stopAndCheck : _record,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Stop' : 'Repeat It'),
                ),
              ],
            ),
            if (_isListening && _lastResult != null) ...[
              const SizedBox(height: 12),
              Text('Heard so far: "${_lastResult!.transcript}"',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
            ],
            const SizedBox(height: 20),
            if (_isChecking) const CircularProgressIndicator(),
            if (_feedback != null) _buildFeedback(_feedback!),
            const Spacer(),
            if (_feedback != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _nextSentence,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Sentence'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(ShadowingFeedback f) {
    if (!f.reliable) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(f.matchSummary),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.matchSummary),
          if (f.topFocus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Focus: ${f.topFocus}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (f.encouragement.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(f.encouragement, style: const TextStyle(color: Colors.green)),
          ],
        ],
      ),
    );
  }
}
