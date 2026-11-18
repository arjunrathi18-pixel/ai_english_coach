import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_quiz_engine.dart';
import 'academy_progress_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Runs a list of multiple-choice questions one at a time with instant
/// feedback and an explanation for every answer, then reports the score.
class AcademyQuizRunner extends StatefulWidget {
  final List<QuizItem> items;
  final String topic;
  final void Function(int correct, int total)? onFinished;
  const AcademyQuizRunner({super.key, required this.items, required this.topic, this.onFinished});

  @override
  State<AcademyQuizRunner> createState() => _AcademyQuizRunnerState();
}

class _AcademyQuizRunnerState extends State<AcademyQuizRunner> {
  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _done = false;
  final List<String> _wrong = [];

  QuizItem get _q => widget.items[_index];

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (i == _q.answer) {
        _correct++;
      } else {
        _wrong.add(_q.question);
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= widget.items.length) {
      final total = widget.items.length;
      await AcademyProgressStore.update((p) => p.recordQuiz(widget.topic, _correct, total));
      widget.onFinished?.call(_correct, total);
      if (mounted) setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.items.isEmpty) return const Center(child: Text('No questions available for this topic yet.'));

    if (_done) {
      final total = widget.items.length;
      final pct = AcademyQuizEngine.percent(_correct, total);
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('$_correct / $total', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          Text('$pct% correct', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            pct >= 75 ? 'Strong result on "${widget.topic}".' : 'Keep practising "${widget.topic}" — review the explanations below.',
            style: theme.textTheme.bodyMedium,
          ),
          if (_wrong.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Questions to review', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ..._wrong.map((w) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $w'))),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        LinearProgressIndicator(value: (_index + (_picked != null ? 1 : 0)) / widget.items.length, minHeight: 6),
        const SizedBox(height: AppSpacing.md),
        Text('Question ${_index + 1} of ${widget.items.length} · ${_q.level}', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(_q.question, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(_q.options.length, (i) {
          Color? border;
          if (_picked != null) {
            if (i == _q.answer) {
              border = AppColors.success;
            } else if (i == _picked) {
              border = AppColors.error;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              onTap: () => _pick(i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: border ?? theme.dividerColor, width: border == null ? 1 : 2),
                ),
                child: Text(_q.options[i], style: theme.textTheme.bodyLarge),
              ),
            ),
          );
        }),
        if (_picked != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (_picked == _q.answer ? AppColors.success : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text('${_picked == _q.answer ? 'Correct. ' : 'Not quite. '}${_q.why}'),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: _index + 1 >= widget.items.length ? 'Finish' : 'Next', onPressed: _next),
        ],
      ],
    );
  }
}

/// Quiz hub: choose a topic, see weak topics, and take a quiz.
class AcademyQuizScreen extends StatefulWidget {
  const AcademyQuizScreen({super.key});

  @override
  State<AcademyQuizScreen> createState() => _AcademyQuizScreenState();
}

class _AcademyQuizScreenState extends State<AcademyQuizScreen> {
  AcademyProgress? _progress;
  List<QuizItem>? _active;
  String _activeTopic = '';
  final _timer = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    AcademyProgressStore.load().then((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  @override
  void dispose() {
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  void _start(String? topic) {
    setState(() {
      _activeTopic = topic ?? 'Mixed quiz';
      _active = AcademyQuizEngine.build(topic: topic, count: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_active != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_activeTopic),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _active = null)),
        ),
        body: AcademyQuizRunner(items: _active!, topic: _activeTopic, onFinished: (c, t) => setState(() {})),
      );
    }
    final weak = _progress?.weakTopics() ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          PrimaryButton(label: 'Mixed quiz (10 questions)', icon: Icons.shuffle, onPressed: () => _start(null)),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Needs practice', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: weak.map((t) => ActionChip(label: Text(t), onPressed: () => _start(t))).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Choose a topic', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ...AcademyQuizEngine.topics().map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(t),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _start(t),
                ),
              )),
        ],
      ),
    );
  }
}
