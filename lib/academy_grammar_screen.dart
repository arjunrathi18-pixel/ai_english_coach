import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'academy_quiz_screen.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Grammar Academy: lessons grouped by level. A level opens when the
/// learner has completed 70% of the previous level's lessons, or when they
/// choose their level manually on the Academy home screen.
class AcademyGrammarScreen extends StatefulWidget {
  const AcademyGrammarScreen({super.key});

  @override
  State<AcademyGrammarScreen> createState() => _AcademyGrammarScreenState();
}

/// How far the learner may go: the manual choice, advanced automatically
/// while 70% of each unlocked level's lessons are completed.
int effectiveUnlockedLevel(AcademyProgress p) {
  var level = p.unlockedUpTo;
  while (level < kAcademyLevels.length - 1) {
    final here = AcademyRepository.lessonsForLevel(kAcademyLevels[level].id);
    if (here.isEmpty) {
      level++;
      continue;
    }
    final done = here.where((l) => p.completedLessons.contains(l.id)).length;
    if (done * 100 / here.length >= 70) {
      level++;
    } else {
      break;
    }
  }
  return level;
}

class _AcademyGrammarScreenState extends State<AcademyGrammarScreen> {
  AcademyProgress? _p;
  final _timer = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  Future<void> _load() async {
    final p = await AcademyProgressStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _p;
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Academy')),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Each lesson has a Hindi explanation, rules, 10 examples, common mistakes and a short practice test. '
                  'Everything works offline.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...kAcademyLevels.map((level) {
                  final lessons = AcademyRepository.lessonsForLevel(level.id);
                  final unlocked = level.order <= effectiveUnlockedLevel(p);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Text('${level.id} — ${level.name}',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Text(level.hindi, style: theme.textTheme.bodySmall),
                            const Spacer(),
                            if (!unlocked) const Icon(Icons.lock_outline, size: 18),
                          ],
                        ),
                      ),
                      if (lessons.isEmpty)
                        Text('No lessons in this level yet.', style: theme.textTheme.bodySmall)
                      else
                        ...lessons.map((l) {
                          final done = p.completedLessons.contains(l.id);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(done ? Icons.check_circle : (unlocked ? Icons.menu_book_outlined : Icons.lock_outline),
                                  color: done ? AppColors.success : null),
                              title: Text(l.title),
                              subtitle: Text(done ? 'Completed · best ${p.lessonBest[l.id] ?? 0}%' : l.english,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () async {
                                if (!unlocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Complete 70% of the previous level, or set your level on the Academy home screen.'),
                                  ));
                                  return;
                                }
                                await Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => AcademyLessonScreen(lesson: l)));
                                _load();
                              },
                            ),
                          );
                        }),
                    ],
                  );
                }),
              ],
            ),
    );
  }
}

class AcademyLessonScreen extends StatefulWidget {
  final GrammarLesson lesson;
  const AcademyLessonScreen({super.key, required this.lesson});

  @override
  State<AcademyLessonScreen> createState() => _AcademyLessonScreenState();
}

class _AcademyLessonScreenState extends State<AcademyLessonScreen> {
  final SpeechService _speech = SpeechService();
  final _timer = Stopwatch()..start();
  bool _practicing = false;

  @override
  void dispose() {
    _speech.stopSpeaking();
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  Widget _section(ThemeData theme, String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentPrimary)),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.lesson;

    if (_practicing) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice: ${l.title}'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _practicing = false)),
        ),
        body: AcademyQuizRunner(
          items: l.drills,
          topic: l.title,
          onFinished: (c, t) async {
            final pct = (c * 100 / t).round();
            await AcademyProgressStore.update((p) {
              if (pct > (p.lessonBest[l.id] ?? 0)) p.lessonBest[l.id] = pct;
              if (pct >= 75) p.completedLessons.add(l.id);
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _section(theme, 'हिंदी में समझिए', Text(l.hindi, style: theme.textTheme.bodyLarge)),
          _section(theme, 'Definition', Text(l.english, style: theme.textTheme.bodyLarge)),
          _section(
            theme,
            'Rules / Formula',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(l.rule, style: theme.textTheme.bodyMedium),
            ),
          ),
          _section(
            theme,
            'Examples (tap the speaker to listen)',
            Column(
              children: l.examples
                  .map((e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.en),
                        subtitle: Text(e.hi),
                        trailing: IconButton(icon: const Icon(Icons.volume_up_outlined), onPressed: () => _speech.speak(e.en)),
                      ))
                  .toList(),
            ),
          ),
          _section(
            theme,
            'Common mistakes',
            Column(
              children: l.mistakes
                  .map((m) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✗  ${m.wrong}', style: const TextStyle(color: AppColors.error)),
                            Text('✓  ${m.right}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(m.why, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          PrimaryButton(label: 'Take the practice test', icon: Icons.quiz_outlined, onPressed: () => setState(() => _practicing = true)),
          const SizedBox(height: AppSpacing.sm),
          Text('Score 75% or more to complete this lesson.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
