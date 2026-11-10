import 'package:flutter/material.dart';
import 'vocabulary_item.dart';
import 'vocabulary_service.dart';
import 'vocabulary_store.dart';
import 'curriculum_store.dart';
import 'curriculum.dart';
import 'grammar_service.dart';
import 'grammar_models.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

/// Dedicated REVIEW mode (Prompt 20 mode list; spaced review in Prompts
/// 15 and 18). One session that recycles what is actually due: words
/// whose review is due, and the learner's top recurring mistake patterns
/// turned into grammar drills. If nothing is due, it says so honestly.
class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final GrammarService _grammarService = GrammarService();
  final _controller = TextEditingController();

  List<VocabularyItem> _dueWords = [];
  List<RecurringMistake> _mistakes = [];
  int _index = 0;
  bool _loading = true;
  bool _checking = false;
  String? _feedback;
  bool? _correct;
  GrammarDrill? _drill;
  GrammarEvalResult? _drillResult;
  String _level = 'unknown';
  int _done = 0;

  // Steps: first all due words, then up to 2 mistake drills.
  int get _totalSteps => _dueWords.length + (_mistakes.length > 2 ? 2 : _mistakes.length);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await ProfileStore.load();
    final words = await VocabularyStore.dueForReview(limit: 5);
    final mistakes = await CurriculumStore.loadMistakes();
    mistakes.sort((a, b) => b.timesObserved.compareTo(a.timesObserved));
    setState(() {
      _level = profile?.overallLevel ?? 'unknown';
      _dueWords = words;
      _mistakes = mistakes;
      _loading = false;
    });
    await _prepareStep();
  }

  bool get _isWordStep => _index < _dueWords.length;

  Future<void> _prepareStep() async {
    if (_index >= _totalSteps) return;
    if (!_isWordStep) {
      final m = _mistakes[_index - _dueWords.length];
      setState(() => _checking = true);
      final drill = await _grammarService.generateDrill(topic: m.pattern, level: _level);
      setState(() {
        _drill = drill;
        _checking = false;
      });
    }
  }

  Future<void> _check() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _checking = true);
    if (_isWordStep) {
      final item = _dueWords[_index];
      final result = await _vocabService.evaluate(item: item, learnerAttempt: _controller.text.trim());
      if (result != null) {
        final (correct, feedback, counts) = result;
        if (counts) {
          item.registerSuccessfulUse();
        } else {
          item.registerAttemptWithoutSuccess();
        }
        await VocabularyStore.update(item);
        _correct = correct;
        _feedback = feedback;
      }
    } else if (_drill != null) {
      final r = await _grammarService.evaluate(drill: _drill!, learnerAnswer: _controller.text.trim());
      _drillResult = r;
      _correct = r?.correct;
      _feedback = r == null ? null : '${r.correctAnswer} — ${r.explanation}';
    }
    setState(() => _checking = false);
  }

  Future<void> _next() async {
    _done++;
    final finished = _index + 1 >= _totalSteps;
    setState(() {
      _index++;
      _controller.clear();
      _feedback = null;
      _correct = null;
      _drill = null;
      _drillResult = null;
    });
    if (finished) {
      await GamificationService.recordCompletion(xp: 20);
    } else {
      await _prepareStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Session')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _totalSteps == 0
              ? const AppEmptyState(
                  icon: Icons.check_circle_outline,
                  message: 'Nothing is due for review right now.\nPractice more and items will appear here.',
                )
              : _index >= _totalSteps
                  ? AppEmptyState(
                      icon: Icons.celebration_outlined,
                      message: 'Review complete — you reviewed $_done item${_done == 1 ? '' : 's'}.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      children: [
                        Text('Item ${_index + 1} of $_totalSteps', style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        if (_isWordStep) ...[
                          Text(_dueWords[_index].word,
                              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(_dueWords[_index].practicePrompt),
                        ] else if (_drill != null) ...[
                          Text(_drill!.instruction, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Text(_drill!.prompt, style: theme.textTheme.titleLarge),
                        ] else
                          const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _controller,
                          enabled: _feedback == null,
                          decoration: const InputDecoration(hintText: 'Your answer…', border: OutlineInputBorder()),
                          onSubmitted: (_) => _check(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_feedback == null)
                          PrimaryButton(label: 'Check', loading: _checking, onPressed: _check)
                        else ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: ((_correct ?? false) ? AppColors.success : AppColors.warning).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            child: Text(_feedback!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(label: _index + 1 >= _totalSteps ? 'Finish' : 'Next', onPressed: _next),
                        ],
                      ],
                    ),
    );
  }
}
