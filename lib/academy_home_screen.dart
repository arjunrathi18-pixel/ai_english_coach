import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'academy_grammar_screen.dart';
import 'academy_vocab_screen.dart';
import 'academy_sentences_screen.dart';
import 'academy_quiz_screen.dart';
import 'academy_interview_screen.dart';
import 'academy_roleplay_screen.dart';
import 'academy_reading_screen.dart';
import 'academy_search_screen.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Offline Academy hub. It never calls an API or checks the network —
/// it opens in airplane mode. All content is bundled in the app.
class AcademyHomeScreen extends StatefulWidget {
  const AcademyHomeScreen({super.key});

  @override
  State<AcademyHomeScreen> createState() => _AcademyHomeScreenState();
}

class _AcademyHomeScreenState extends State<AcademyHomeScreen> {
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

  Future<void> _go(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  Future<void> _chooseLevel() async {
    final p = _p!;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('I already know up to…'),
        children: [
          for (final l in kAcademyLevels)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.order),
              child: Text('${l.id} — ${l.name}${l.order == p.unlockedUpTo ? '  (current)' : ''}'),
            ),
        ],
      ),
    );
    if (picked != null) {
      await AcademyProgressStore.update((pr) => pr.unlockedUpTo = picked);
      _load();
    }
  }

  double _fraction(int done, int total) => total == 0 ? 0 : (done / total).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _p;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Academy'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => _go(const AcademySearchScreen()))],
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.airplanemode_active, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Works with no internet and no AI. This is saved learning content — not generative AI.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(theme, '🔥 ${p.streak} day streak'),
                    _chip(theme, '⏱ ${p.minutes} min learned'),
                    _chip(theme, '📘 ${p.completedLessons.length}/${AcademyRepository.lessons.length} lessons'),
                    _chip(theme, '🔤 ${p.wordsMastered} words mastered'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _todayPlan(theme, p),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Learn'),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.rule_outlined, title: 'Grammar Academy', subtitle: '${AcademyRepository.lessons.length} lessons with Hindi explanations', onTap: () => _go(const AcademyGrammarScreen())),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.style_outlined, title: 'Vocabulary & Flashcards', subtitle: '${AcademyRepository.words.length} words · spaced repetition', onTap: () => _go(const AcademyVocabScreen())),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.chat_bubble_outline, title: 'Daily Sentences', subtitle: '${AcademyRepository.sentences.length} sentences with Hindi + speaking practice', onTap: () => _go(const AcademySentencesScreen())),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.article_outlined, title: 'Reading', subtitle: '${AcademyRepository.passages.length} passages with questions', onTap: () => _go(const AcademyReadingScreen())),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Practise'),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.quiz_outlined, title: 'Quizzes', subtitle: '${AcademyRepository.staticQuizItems.length}+ questions · weak-topic review', onTap: () => _go(const AcademyQuizScreen())),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.work_outline, title: 'Interview Prep', subtitle: '${AcademyRepository.interviews.length} questions · mock interview timer', onTap: () => _go(const AcademyInterviewScreen())),
                const SizedBox(height: AppSpacing.md),
                AppActionCard(icon: Icons.theater_comedy_outlined, title: 'Guided Roleplay', subtitle: '${AcademyRepository.roleplays.length} scripted scenarios', onTap: () => _go(const AcademyRoleplayScreen())),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Expanded(child: SectionHeader(title: 'Levels')),
                    TextButton(onPressed: _chooseLevel, child: const Text('Set my level')),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...kAcademyLevels.map((l) {
                  final lessons = AcademyRepository.lessonsForLevel(l.id);
                  final done = lessons.where((x) => p.completedLessons.contains(x.id)).length;
                  final unlocked = l.order <= effectiveUnlockedLevel(p);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${l.id} · ${l.name}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                            Icon(unlocked ? Icons.lock_open : Icons.lock_outline, size: 18),
                          ],
                        ),
                        Text(l.hindi, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        if (lessons.isEmpty)
                          Text('No lessons for this level in this version yet.', style: theme.textTheme.bodySmall)
                        else ...[
                          LinearProgressIndicator(value: _fraction(done, lessons.length), minHeight: 6),
                          const SizedBox(height: 2),
                          Text('$done / ${lessons.length} lessons completed', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Content size in this version: ${AcademyRepository.words.length} words, ${AcademyRepository.sentences.length} sentences, '
                  '${AcademyRepository.lessons.length} grammar lessons, ${AcademyRepository.interviews.length} interview questions, '
                  '${AcademyRepository.roleplays.length} roleplays, ${AcademyRepository.passages.length} reading passages. More packs are planned.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
    );
  }

  Widget _chip(ThemeData theme, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(text, style: theme.textTheme.labelMedium),
      );

  Widget _todayPlan(ThemeData theme, AcademyProgress p) {
    final due = p.dueWords().length;
    final newWords = AcademyRepository.words.where((w) => !p.srBox.containsKey(w.word)).length;
    final nextLesson = AcademyRepository.lessons.where((l) => !p.completedLessons.contains(l.id) && academyLevelOrder(l.level) <= effectiveUnlockedLevel(p)).toList();
    final nextRead = AcademyRepository.passages.where((r) => !p.readingDone.contains(r.id)).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accentPrimary, Color(0xFF4B45C9)]),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's plan", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('• Vocabulary: $due due for review, $newWords new words available (goal ${p.dailyWordGoal})', style: const TextStyle(color: Colors.white)),
          Text(nextLesson.isEmpty ? '• Grammar: all unlocked lessons completed' : '• Grammar: ${nextLesson.first.title}', style: const TextStyle(color: Colors.white)),
          const Text('• Sentences: practise 5 sentences aloud', style: TextStyle(color: Colors.white)),
          Text(nextRead.isEmpty ? '• Reading: all passages done' : '• Reading: ${nextRead.first.title}', style: const TextStyle(color: Colors.white)),
          if (p.weakTopics().isNotEmpty) Text('• Revise: ${p.weakTopics().first}', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
