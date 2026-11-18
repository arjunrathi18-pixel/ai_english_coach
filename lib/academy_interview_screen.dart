import 'dart:async';
import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Interview preparation: question bank with Hindi, sample and professional
/// answers, structure tips and common mistakes — plus an offline mock
/// interview with a timer and a self-evaluation checklist. (No AI judge:
/// you compare yourself with the model answers.)
class AcademyInterviewScreen extends StatefulWidget {
  const AcademyInterviewScreen({super.key});

  @override
  State<AcademyInterviewScreen> createState() => _AcademyInterviewScreenState();
}

class _AcademyInterviewScreenState extends State<AcademyInterviewScreen> {
  final SpeechService _speech = SpeechService();
  final _timer = Stopwatch()..start();
  AcademyProgress? _p;
  String? _category;

  @override
  void initState() {
    super.initState();
    AcademyProgressStore.load().then((p) {
      if (mounted) setState(() => _p = p);
    });
  }

  @override
  void dispose() {
    _speech.stopSpeaking();
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  List<String> get _categories => AcademyRepository.interviews.map((i) => i.category).toSet().toList();

  Future<void> _open(InterviewItem q) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _InterviewDetail(item: q)));
    final p = await AcademyProgressStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = AcademyRepository.interviews.where((i) => _category == null || i.category == _category).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Prep')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          PrimaryButton(
            label: 'Start a mock interview',
            icon: Icons.timer_outlined,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _MockInterview(category: _category))),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (v) => setState(() => _category = v ? c : null)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${items.length} questions · ${_p?.interviewDone.length ?? 0} practised', style: theme.textTheme.bodySmall),
          ...items.map((q) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(_p?.interviewDone.contains(q.id) ?? false ? Icons.check_circle : Icons.help_outline,
                      color: _p?.interviewDone.contains(q.id) ?? false ? AppColors.success : null),
                  title: Text(q.question),
                  subtitle: Text(q.category),
                  onTap: () => _open(q),
                ),
              )),
        ],
      ),
    );
  }
}

class _InterviewDetail extends StatelessWidget {
  final InterviewItem item;
  const _InterviewDetail({required this.item});

  Widget _block(ThemeData theme, String title, String body, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (color ?? theme.dividerColor).withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speech = SpeechService();
    return Scaffold(
      appBar: AppBar(title: Text(item.category)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(item.question, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(item.hindi, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _block(theme, 'Simple answer', item.sample, color: AppColors.accentSecondary),
          _block(theme, 'Professional answer', item.professional, color: AppColors.accentPrimary),
          _block(theme, 'Answer structure', item.structure),
          _block(theme, 'Useful vocabulary', item.vocab.join(' · ')),
          _block(theme, 'Common mistake', item.mistake, color: AppColors.warning),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Listen to answer', icon: Icons.volume_up_outlined, onPressed: () => speech.speak(item.professional))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Mark practised',
                  icon: Icons.check,
                  onPressed: () async {
                    await AcademyProgressStore.update((p) {
                      p.interviewDone.add(item.id);
                      p.touch();
                    });
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Offline mock interview: shuffled questions, a 60-second answer timer,
/// the model answer after you speak, and a self-evaluation checklist.
class _MockInterview extends StatefulWidget {
  final String? category;
  const _MockInterview({this.category});

  @override
  State<_MockInterview> createState() => _MockInterviewState();
}

class _MockInterviewState extends State<_MockInterview> {
  final SpeechService _speech = SpeechService();
  late final List<InterviewItem> _qs;
  int _i = 0;
  int _seconds = 60;
  Timer? _tick;
  bool _showModel = false;
  final List<bool> _checks = [false, false, false];
  int _selfScore = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _qs = AcademyRepository.interviews.where((q) => widget.category == null || q.category == widget.category).toList()..shuffle();
    if (_qs.length > 5) _qs.removeRange(5, _qs.length);
    _speech.speak(_qs.isEmpty ? '' : _qs.first.question);
    _startTimer();
  }

  void _startTimer() {
    _tick?.cancel();
    _seconds = 60;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _speech.stopSpeaking();
    super.dispose();
  }

  Future<void> _next() async {
    _selfScore += _checks.where((c) => c).length;
    final id = _qs[_i].id;
    await AcademyProgressStore.update((p) {
      p.interviewDone.add(id);
      p.touch();
    });
    if (_i + 1 >= _qs.length) {
      _tick?.cancel();
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _i++;
      _showModel = false;
      for (var k = 0; k < _checks.length; k++) {
        _checks[k] = false;
      }
    });
    _speech.speak(_qs[_i].question);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_qs.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Mock interview')), body: const Center(child: Text('No questions.')));
    if (_finished) {
      final max = _qs.length * 3;
      return Scaffold(
        appBar: AppBar(title: const Text('Mock interview')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Self-evaluation: $_selfScore / $max', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text('This is your own checklist result — offline mode has no AI interviewer. Review the model answers for any question you found difficult.',
                  style: theme.textTheme.bodyMedium),
              const Spacer(),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      );
    }
    final q = _qs[_i];
    return Scaffold(
      appBar: AppBar(title: Text('Question ${_i + 1} of ${_qs.length}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Row(
            children: [
              Expanded(child: Text(q.question, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              Text('$_seconds s', style: theme.textTheme.headlineSmall?.copyWith(color: _seconds <= 10 ? AppColors.error : null)),
            ],
          ),
          Text(q.hindi, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text('Answer out loud now. Structure: ${q.structure}', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          if (!_showModel)
            SecondaryButton(label: 'Show model answer', onPressed: () => setState(() => _showModel = true))
          else ...[
            Text('Professional answer', style: theme.textTheme.labelLarge),
            Text(q.professional, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Text('Self-evaluation', style: theme.textTheme.labelLarge),
            for (final entry in const ['I answered the question directly', 'I gave an example or result', 'I finished within the time'].asMap().entries)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                value: _checks[entry.key],
                onChanged: (v) => setState(() => _checks[entry.key] = v ?? false),
              ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: _i + 1 >= _qs.length ? 'Finish' : 'Next question', onPressed: _next),
          ],
        ],
      ),
    );
  }
}
