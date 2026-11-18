import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'vocabulary_item.dart';
import 'vocabulary_service.dart';
import 'vocabulary_store.dart';
import 'curriculum.dart' show MasteryStageLabel;
import 'profile_store.dart';
import 'gamification_service.dart';
import 'local_content.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final TextEditingController _lookupController = TextEditingController();
  final TextEditingController _practiceController = TextEditingController();
  final VocabularyService _service = VocabularyService();

  VocabularyItem? _current;
  bool _loadingLookup = false;
  bool _checking = false;
  String? _feedback;
  bool? _lastCorrect;

  List<VocabularyItem> _reviewList = [];
  String _accent = 'indian';
  String _level = 'unknown';

  @override
  void initState() {
    super.initState();
    _loadReviewList();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  Future<void> _loadReviewList() async {
    final items = await VocabularyStore.dueForReview();
    setState(() => _reviewList = items);
  }

  VocabularyItem? _starterFor(String term) {
    final t = term.trim().toLowerCase();
    for (final m in kStarterVocabulary) {
      if ((m['word'] as String).toLowerCase() == t) {
        return VocabularyItem(
          word: m['word'] as String,
          category: m['category'] as String,
          meaning: m['meaning'] as String,
          simpleExplanation: m['simple'] as String,
          examples: List<String>.from(m['examples'] as List),
          collocations: List<String>.from(m['collocations'] as List),
          register: m['register'] as String,
          nuanceOrSynonyms: m['nuance'] as String,
          practicePrompt: m['practice'] as String,
        );
      }
    }
    return null;
  }

  Future<void> _lookUp([String? word, bool preferLocal = false]) async {
    final term = word ?? _lookupController.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _loadingLookup = true;
      _current = null;
      _feedback = null;
      _practiceController.clear();
    });
    VocabularyItem? result = preferLocal ? _starterFor(term) : null;
    result ??= await _service.explain(
      wordOrPhrase: term,
      accent: _accent,
      level: _level,
    );
    // AI unavailable? Fall back to the built-in starter list when possible.
    result ??= _starterFor(term);
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not look that up. Connect the AI in Profile > AI Connection, or try a starter word.'),
        ),
      );
    }
    if (result != null) {
      await VocabularyStore.upsertNew(result);
      await _loadReviewList();
    }
    setState(() {
      _current = result;
      _loadingLookup = false;
    });
  }

  Future<void> _checkPractice() async {
    if (_current == null || _practiceController.text.trim().isEmpty) return;
    setState(() => _checking = true);
    final result = await _service.evaluate(
      item: _current!,
      learnerAttempt: _practiceController.text.trim(),
    );
    if (result != null) {
      final (correct, feedback, counts) = result;
      if (counts) {
        _current!.registerSuccessfulUse();
        await GamificationService.recordCompletion(xp: 10);
      } else {
        _current!.registerAttemptWithoutSuccess();
      }
      await VocabularyStore.update(_current!);
      await _loadReviewList();
      setState(() {
        _lastCorrect = correct;
        _feedback = feedback;
      });
    } else {
      // AI unavailable: honest basic check only (no mastery change, no XP).
      final attempt = _practiceController.text.trim().toLowerCase();
      final used = attempt.contains(_current!.word.toLowerCase());
      final long = attempt.split(RegExp(r'\s+')).length >= 4;
      setState(() {
        _lastCorrect = used && long;
        _feedback = used && long
            ? 'Good — you used "${_current!.word}" in a full sentence. '
                '(Basic offline check. Connect the AI for detailed feedback and mastery tracking.)'
            : 'Try a full sentence (4+ words) that includes "${_current!.word}". '
                '(Basic offline check.)';
      });
    }
    setState(() => _checking = false);
  }

  @override
  void dispose() {
    _lookupController.dispose();
    _practiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vocabulary')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lookupController,
                    decoration: const InputDecoration(
                      hintText: 'Look up a word or phrase…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _lookUp(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadingLookup ? null : () => _lookUp(),
                  child: const Text('Go'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingLookup) const Center(child: CircularProgressIndicator()),
            if (_current != null) Expanded(child: _buildDetail(_current!)),
            if (_current == null && !_loadingLookup)
              Expanded(child: _buildReviewList()),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    if (_reviewList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Look up a word above, or tap a starter word to begin your list.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: kStarterVocabulary
                    .map((m) => ActionChip(
                          label: Text(m['word'] as String),
                          onPressed: () => _lookUp(m['word'] as String, true),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      children: [
        const Text('Worth reviewing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._reviewList.map((v) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(v.word),
                subtitle: Text(v.masteryStage.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _lookUp(v.word),
              ),
            )),
      ],
    );
  }

  Widget _buildDetail(VocabularyItem item) {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.word,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Chip(label: Text(item.masteryStage.label)),
          ],
        ),
        const SizedBox(height: 8),
        Text(item.meaning),
        if (item.simpleExplanation.isNotEmpty &&
            item.simpleExplanation != item.meaning) ...[
          const SizedBox(height: 4),
          Text(item.simpleExplanation,
              style: const TextStyle(color: Colors.grey)),
        ],
        const SizedBox(height: 12),
        if (item.examples.isNotEmpty) ...[
          const Text('Examples', style: TextStyle(fontWeight: FontWeight.w600)),
          ...item.examples.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $e'),
              )),
          const SizedBox(height: 10),
        ],
        if (item.collocations.isNotEmpty) ...[
          const Text('Common collocations',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                item.collocations.map((c) => Chip(label: Text(c))).toList(),
          ),
          const SizedBox(height: 10),
        ],
        if (item.nuanceOrSynonyms.isNotEmpty) ...[
          Text('Nuance: ${item.nuanceOrSynonyms}',
              style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
        ],
        const Divider(height: 28),
        const Text('Your turn', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(item.practicePrompt),
        const SizedBox(height: 10),
        TextField(
          controller: _practiceController,
          decoration: const InputDecoration(
            hintText: 'Use it in a sentence…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _checkPractice(),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _checking ? null : _checkPractice,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Check'),
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_lastCorrect == true ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_feedback!),
          ),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() {
            _current = null;
            _feedback = null;
            _lookupController.clear();
          }),
          child: const Text('← Back to my list'),
        ),
      ],
    );
  }
}
