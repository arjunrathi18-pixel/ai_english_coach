import 'package:flutter/material.dart';
import 'gamification_models.dart';
import 'gamification_store.dart';
import 'vocabulary_store.dart';
import 'curriculum.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Prompt 17 (badges, milestones): every badge is computed from REAL
/// stored data only (sessions completed, best streak, XP, vocabulary).
/// No fake dates, no invented achievements. Locked badges show honest
/// progress toward the requirement.
class _Badge {
  final String icon;
  final String title;
  final String description;
  final int current;
  final int target;
  _Badge(this.icon, this.title, this.description, this.current, this.target);
  bool get earned => current >= target;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<_Badge> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final LearnerStats s = await GamificationStore.load();
    final vocab = await VocabularyStore.loadAll();
    final masteredWords = vocab.where((v) => v.masteryStage == MasteryStage.mastered).length;
    setState(() {
      _badges = [
        _Badge('🌱', 'First Step', 'Complete your first practice session', s.totalSessionsCompleted, 1),
        _Badge('🗣️', 'Regular Speaker', 'Complete 10 practice sessions', s.totalSessionsCompleted, 10),
        _Badge('🎯', 'Dedicated Learner', 'Complete 25 practice sessions', s.totalSessionsCompleted, 25),
        _Badge('🏅', 'Committed', 'Complete 50 practice sessions', s.totalSessionsCompleted, 50),
        _Badge('🔥', '3-Day Streak', 'Practice 3 days in a row', s.bestStreak, 3),
        _Badge('⚡', '7-Day Streak', 'Practice 7 days in a row', s.bestStreak, 7),
        _Badge('💎', '30-Day Streak', 'Practice 30 days in a row', s.bestStreak, 30),
        _Badge('⭐', '100 XP', 'Earn 100 XP through practice', s.totalXp, 100),
        _Badge('🌟', '500 XP', 'Earn 500 XP through practice', s.totalXp, 500),
        _Badge('📖', 'Vocabulary Builder', 'Track 10 words in My Vocabulary', vocab.length, 10),
        _Badge('✅', 'Word Master', 'Master your first word', masteredWords, 1),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = _badges.where((b) => b.earned).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text('$earned of ${_badges.length} earned',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Badges reflect real practice — XP is practice, not English level.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: AppSpacing.xl),
                ..._badges.map((b) => _tile(theme, b)),
              ],
            ),
    );
  }

  Widget _tile(ThemeData theme, _Badge b) {
    final progress = (b.current / b.target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: b.earned ? AppColors.accentPrimary.withOpacity(0.08) : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: b.earned ? AppColors.accentPrimary : theme.dividerColor),
      ),
      child: Row(
        children: [
          Opacity(opacity: b.earned ? 1 : 0.35, child: Text(b.icon, style: const TextStyle(fontSize: 30))),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(b.description, style: theme.textTheme.bodySmall),
                if (!b.earned) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${b.current} / ${b.target}', style: theme.textTheme.labelSmall),
                ],
              ],
            ),
          ),
          if (b.earned) const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }
}
