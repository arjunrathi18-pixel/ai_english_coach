import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'pronunciation_service.dart';
import 'pronunciation_models.dart';

class MinimalPairsScreen extends StatefulWidget {
  const MinimalPairsScreen({super.key});

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final TextEditingController _soundController = TextEditingController();
  final PronunciationService _pronunciation = PronunciationService();
  final SpeechService _speech = SpeechService();

  MinimalPairSet? _set;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _speech.init();
  }

  Future<void> _generate() async {
    final desc = _soundController.text.trim();
    if (desc.isEmpty) return;
    setState(() {
      _loading = true;
      _set = null;
    });
    final result = await _pronunciation.getMinimalPairs(desc);
    setState(() {
      _set = result;
      _loading = false;
    });
  }

  Future<void> _playWord(String word) async {
    await _speech.speak(word);
  }

  @override
  void dispose() {
    _soundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Pairs')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe a sound you find tricky, e.g. "th sound" or "ship vs sheep vowel".',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soundController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. "th sound"',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _generate,
                  child: const Text('Go'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_set != null) ...[
              Text(_set!.contrastLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _set!.pairs.length,
                  itemBuilder: (context, index) {
                    final pair = _set!.pairs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _wordChip(pair.a),
                            const Text('vs'),
                            _wordChip(pair.b),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wordChip(String word) {
    return ActionChip(
      label: Text(word, style: const TextStyle(fontSize: 16)),
      avatar: const Icon(Icons.volume_up, size: 18),
      onPressed: () => _playWord(word),
    );
  }
}
