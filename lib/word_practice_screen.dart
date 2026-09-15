import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'recognition_result.dart';
import 'pronunciation_service.dart';
import 'pronunciation_models.dart';
import 'profile_store.dart';

class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({super.key});

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  final TextEditingController _wordController = TextEditingController();
  final SpeechService _speech = SpeechService();
  final PronunciationService _pronunciation = PronunciationService();

  PhoneticInfo? _info;
  bool _loadingInfo = false;
  bool _isListening = false;
  RecognitionResult? _lastResult;
  String _accent = 'indian';
  String _level = 'unknown';

  @override
  void initState() {
    super.initState();
    _speech.init();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  Future<void> _lookUp() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;
    setState(() {
      _loadingInfo = true;
      _info = null;
      _lastResult = null;
    });
    final info = await _pronunciation.getPhoneticInfo(
      word: word,
      accent: _accent,
      level: _level,
    );
    setState(() {
      _info = info;
      _loadingInfo = false;
    });
  }

  Future<void> _playWord() async {
    if (_info == null) return;
    await _speech.setAccent(_accent);
    await _speech.speak(_info!.word);
  }

  Future<void> _toggleRecord() async {
    if (_isListening) {
      await _speech.stopListening();
      setState(() => _isListening = false);
      return;
    }
    if (!_speech.isAvailable) {
      final ok = await _speech.init();
      if (!ok) return;
    }
    setState(() {
      _isListening = true;
      _lastResult = null;
    });
    await _speech.startListeningDetailed(
      onResult: (result) => setState(() => _lastResult = result),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Practice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      hintText: 'Type a word, e.g. "opportunity"',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _lookUp(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadingInfo ? null : _lookUp,
                  child: const Text('Go'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loadingInfo) const Center(child: CircularProgressIndicator()),
            if (_info != null) Expanded(child: _buildInfo(_info!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(PhoneticInfo info) {
    return ListView(
      children: [
        Text(info.word,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('IPA: ${info.ipa}', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 6),
        Text(info.simpleSpelling, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: info.syllables.asMap().entries.map((e) {
            final isStressed = e.key == info.stressedSyllableIndex;
            return Chip(
              label: Text(e.value.toUpperCase()),
              backgroundColor: isStressed ? Colors.orange.shade100 : null,
              labelStyle: TextStyle(
                fontWeight: isStressed ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(info.tip, style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _playWord,
              icon: const Icon(Icons.volume_up),
              label: const Text('Listen'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _toggleRecord,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Stop' : 'Try It'),
            ),
          ],
        ),
        if (_lastResult != null) ...[
          const SizedBox(height: 16),
          _buildAttemptFeedback(_lastResult!, info.word),
        ],
      ],
    );
  }

  Widget _buildAttemptFeedback(RecognitionResult result, String target) {
    if (!result.audioAvailable) {
      return const Text(
        "Microphone wasn't available for that attempt — try again.",
        style: TextStyle(color: Colors.black54),
      );
    }
    final heard = result.transcript.trim().toLowerCase();
    final closeMatch = heard.contains(target.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (closeMatch ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        closeMatch
            ? 'The recognizer heard "$heard" — that matches well. Nice work!'
            : 'The recognizer heard "$heard", which didn\'t clearly match "$target". '
                'This could be pronunciation, clarity, or just the recognizer — try it slowly again.',
      ),
    );
  }
}
