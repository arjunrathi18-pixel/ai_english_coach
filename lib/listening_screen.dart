import 'package:flutter/material.dart';
import 'listening_service.dart';
import 'listening_models.dart';
import 'speech_service.dart';
import 'profile_store.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final ListeningService _service = ListeningService();
  final SpeechService _speech = SpeechService();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  ListeningPassage? _passage;
  int _questionIndex = 0;
  int _playCount = 0;
  double _speechRate = 0.45;
  bool _loadingPassage = false;
  bool _checking = false;
  String _level = 'unknown';
  String _accent = 'indian';

  final Map<String, ListeningAnswerResult> _results = {};

  @override
  void initState() {
    super.initState();
    _speech.init();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  ListeningQuestion? get _currentQuestion =>
      _passage != null && _questionIndex < _passage!.questions.length
          ? _passage!.questions[_questionIndex]
          : null;

  Future<void> _generatePassage() async {
    setState(() {
      _loadingPassage = true;
      _passage = null;
      _questionIndex = 0;
      _playCount = 0;
      _results.clear();
      _answerController.clear();
    });
    final passage = await _service.generatePassage(
      level: _level,
      accent: _accent,
      topic: _topicController.text.trim(),
    );
    setState(() {
      _passage = passage;
      _loadingPassage = false;
    });
  }

  Future<void> _play() async {
    if (_passage == null) return;
    await _speech.setAccent(_accent);
    await _speech.setSpeechRate(_speechRate);
    await _speech.speak(_passage!.script);
    setState(() => _playCount++);
  }

  Future<void> _submitAnswer() async {
    final question = _currentQuestion;
    if (question == null || _answerController.text.trim().isEmpty) return;

    setState(() => _checking = true);
    final isFirstAttempt = _playCount <= 1;
    final result = await _service.evaluateAnswer(
      passage: _passage!,
      question: question,
      learnerAnswer: _answerController.text.trim(),
      isFirstAttempt: isFirstAttempt,
    );
    setState(() {
      _checking = false;
      if (result != null) _results[question.id] = result;
    });
  }

  void _nextQuestion() {
    setState(() {
      _questionIndex++;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Practice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _passage == null ? _buildSetup() : _buildPassage(),
      ),
    );
  }

  Widget _buildSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional topic (e.g. "phone call", "workplace meeting") — leave blank for general conversation.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _topicController,
          decoration: const InputDecoration(
            hintText: 'Topic (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        if (_loadingPassage)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton.icon(
            onPressed: _generatePassage,
            icon: const Icon(Icons.headphones),
            label: const Text('Start Listening Exercise'),
          ),
      ],
    );
  }

  Widget _buildPassage() {
    final passage = _passage!;
    final question = _currentQuestion;

    if (question == null) {
      return _buildSessionSummary();
    }

    return ListView(
      children: [
        Text(passage.topic,
            style: const TextStyle(fontSize: 14, color: Colors.black45)),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.volume_up),
              label: Text(_playCount == 0 ? 'Listen' : 'Replay ($_playCount)'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _speechRate,
                min: 0.3,
                max: 0.7,
                divisions: 8,
                label: _speechRate < 0.4
                    ? 'Slow'
                    : _speechRate > 0.55
                        ? 'Fast'
                        : 'Normal',
                onChanged: (v) => setState(() => _speechRate = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'First listen for the main idea. Replay if you need to catch details.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const Divider(height: 32),
        Text('Question ${_questionIndex + 1} of ${passage.questions.length}',
            style: const TextStyle(color: Colors.black45)),
        const SizedBox(height: 6),
        Text(question.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Your answer…',
            border: OutlineInputBorder(),
          ),
          enabled: !_results.containsKey(question.id),
        ),
        const SizedBox(height: 10),
        if (!_results.containsKey(question.id))
          FilledButton(
            onPressed: _checking ? null : _submitAnswer,
            child: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Check'),
          ),
        if (_results.containsKey(question.id)) ...[
          const SizedBox(height: 12),
          _buildResultCard(_results[question.id]!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _nextQuestion,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_questionIndex + 1 < passage.questions.length
                ? 'Next Question'
                : 'Finish'),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard(ListeningAnswerResult result) {
    final color = result.judgment == AnswerJudgment.correct
        ? Colors.green
        : result.judgment == AnswerJudgment.partiallyCorrect
            ? Colors.orange
            : Colors.red;
    final label = result.judgment == AnswerJudgment.correct
        ? 'Correct'
        : result.judgment == AnswerJudgment.partiallyCorrect
            ? 'Partially correct'
            : 'Not quite';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(result.feedback),
        ],
      ),
    );
  }

  Widget _buildSessionSummary() {
    final total = _results.length;
    final correct = _results.values
        .where((r) => r.judgment == AnswerJudgment.correct)
        .length;
    final firstAttemptCorrect = _results.values
        .where((r) => r.wasFirstAttempt && r.judgment == AnswerJudgment.correct)
        .length;
    final firstAttemptTotal = _results.values.where((r) => r.wasFirstAttempt).length;

    // Qualitative only — never a fabricated precise percentage
    // (Prompt 8, section 36).
    String overallLabel;
    if (total == 0) {
      overallLabel = 'No data';
    } else if (correct == total) {
      overallLabel = 'Strong';
    } else if (correct >= (total / 2)) {
      overallLabel = 'Developing';
    } else {
      overallLabel = 'Needs Practice';
    }

    return ListView(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(overallLabel,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        const Center(child: Text('Overall comprehension this session')),
        const SizedBox(height: 20),
        Text('You got $correct out of $total questions right.'),
        if (firstAttemptTotal > 0) ...[
          const SizedBox(height: 8),
          Text(
            'First attempt (before replay): $firstAttemptCorrect out of $firstAttemptTotal — '
            'shows your independent listening, separate from supported comprehension.',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _generatePassage,
          child: const Text('Try Another Passage'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
