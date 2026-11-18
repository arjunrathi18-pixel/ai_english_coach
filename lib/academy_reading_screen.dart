import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'academy_quiz_screen.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class AcademyReadingScreen extends StatefulWidget {
  const AcademyReadingScreen({super.key});

  @override
  State<AcademyReadingScreen> createState() => _AcademyReadingScreenState();
}

class _AcademyReadingScreenState extends State<AcademyReadingScreen> {
  final _timer = Stopwatch()..start();
  AcademyProgress? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AcademyProgressStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  void dispose() {
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = [...AcademyRepository.passages]..sort((a, b) => academyLevelOrder(a.level).compareTo(academyLevelOrder(b.level)));
    return Scaffold(
      appBar: AppBar(title: const Text('Reading')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: list
            .map((p) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(_p?.readingDone.contains(p.id) ?? false ? Icons.check_circle : Icons.article_outlined,
                        color: _p?.readingDone.contains(p.id) ?? false ? AppColors.success : null),
                    title: Text(p.title),
                    subtitle: Text('${p.level} · ${p.text.split(' ').length} words'),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ReadingDetail(passage: p)));
                      _load();
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ReadingDetail extends StatefulWidget {
  final ReadingPassage passage;
  const _ReadingDetail({required this.passage});

  @override
  State<_ReadingDetail> createState() => _ReadingDetailState();
}

class _ReadingDetailState extends State<_ReadingDetail> {
  final SpeechService _speech = SpeechService();
  bool _showHindi = false;
  bool _quiz = false;

  @override
  void dispose() {
    _speech.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.passage;
    if (_quiz) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprehension check'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _quiz = false))),
        body: AcademyQuizRunner(
          items: p.questions,
          topic: 'Reading: ${p.title}',
          onFinished: (c, t) async {
            if (c * 100 / t >= 66) {
              await AcademyProgressStore.update((pr) => pr.readingDone.add(p.id));
            }
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(p.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Level ${p.level}', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(p.text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Read aloud', icon: Icons.volume_up_outlined, onPressed: () => _speech.speak(p.text))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: SecondaryButton(label: _showHindi ? 'Hide Hindi' : 'हिंदी सारांश', onPressed: () => setState(() => _showHindi = !_showHindi))),
            ],
          ),
          if (_showHindi) ...[
            const SizedBox(height: AppSpacing.md),
            Text(p.hindi, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Vocabulary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ...p.vocab.map((v) => Text('• ${v.word} — ${v.hindi}')),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Answer the questions', icon: Icons.quiz_outlined, onPressed: () => setState(() => _quiz = true)),
        ],
      ),
    );
  }
}
