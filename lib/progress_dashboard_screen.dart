import 'package:flutter/material.dart';

import 'profile_store.dart';
import 'curriculum_store.dart';
import 'vocabulary_store.dart';
import 'gamification_store.dart';
import 'learner_profile.dart';
import 'curriculum.dart';
import 'vocabulary_item.dart';
import 'gamification_models.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'assessment_screen.dart';
import 'goal_selector_screen.dart';

/// Prompt 16's core rule: NEVER fabricate improvement, trends, or scores
/// beyond what's actually stored. This dashboard shows only a current
/// snapshot of real data (assessment skills, vocabulary mastery counts,
/// recurring mistakes, streak/XP) — no invented percentages, no fake
/// week-over-week graphs, since the app doesn't store historical
/// snapshots to compute a real trend from.
class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  LearnerProfile? _profile;
  LearningRoadmap? _roadmap;
  List<RecurringMistake> _mistakes = [];
  List<VocabularyItem> _vocab = [];
  LearnerStats _stats = LearnerStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileStore.load();
    final roadmap = await CurriculumStore.loadRoadmap();
    final mistakes = await CurriculumStore.loadMistakes();
    final vocab = await VocabularyStore.loadAll();
    final stats = await GamificationStore.load();
    setState(() {
      _profile = profile;
      _roadmap = roadmap;
      _mistakes = mistakes;
      _vocab = vocab;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                _buildLevelCard(theme),
                const SizedBox(height: AppSpacing.xxl),
                _buildStreakRow(theme),
                const SizedBox(height: AppSpacing.xxxl),
                if (_profile != null && _profile!.skills.isNotEmpty) ...[
                  const SectionHeader(title: 'Skill Snapshot'),
                  const SizedBox(height: AppSpacing.md),
                  ..._profile!.skills.entries.map((e) => _skillBar(theme, e.key, e.value)),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
                const SectionHeader(title: 'Vocabulary'),
                const SizedBox(height: AppSpacing.md),
                _buildVocabSummary(theme),
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(title: 'Recurring Mistakes'),
                const SizedBox(height: AppSpacing.md),
                _buildMistakesSummary(theme),
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(title: 'Learning Plan'),
                const SizedBox(height: AppSpacing.md),
                _buildGoalSummary(theme),
              ],
            ),
    );
  }

  Widget _buildLevelCard(ThemeData theme) {
    if (_profile == null) {
      return AppEmptyState(
        icon: Icons.fact_check_outlined,
        message: "Your skill profile hasn't been established yet.\n"
            "Complete a level assessment to unlock your dashboard.",
        ctaLabel: 'Take Assessment',
        onCta: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AssessmentScreen())),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(_profile!.overallLevel,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentPrimary)),
              const Text('Current Level', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assessment confidence: ${_profile!.confidence}%',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(_profile!.recommendedStartingPoint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _statTile(theme, '🔥', '${_stats.currentStreak}', 'Day Streak')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _statTile(theme, '⭐', '${_stats.totalXp}', 'Total XP')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _statTile(theme, '🏆', '${_stats.level}', _stats.levelTitle)),
      ],
    );
  }

  Widget _statTile(ThemeData theme, String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _skillBar(ThemeData theme, String name, SkillScore skill) {
    final label = name[0].toUpperCase() + name.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: skill.score / 100,
                minHeight: 8,
                backgroundColor: theme.dividerColor,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 30, child: Text(skill.level, style: theme.textTheme.labelMedium)),
        ],
      ),
    );
  }

  Widget _buildVocabSummary(ThemeData theme) {
    if (_vocab.isEmpty) {
      return Text(
        'No vocabulary tracked yet — words you look up in My Vocabulary will appear here.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }
    final mastered = _vocab.where((v) => v.masteryStage == MasteryStage.mastered).length;
    final practicing = _vocab.where((v) =>
        v.masteryStage == MasteryStage.practicing || v.masteryStage == MasteryStage.developing).length;
    return Row(
      children: [
        Expanded(child: _statTile(theme, '📖', '${_vocab.length}', 'Tracked')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _statTile(theme, '🔄', '$practicing', 'Practicing')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _statTile(theme, '✅', '$mastered', 'Mastered')),
      ],
    );
  }

  Widget _buildMistakesSummary(ThemeData theme) {
    if (_mistakes.isEmpty) {
      return Text(
        'No recurring patterns tracked yet — these build up as you practice.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }
    final sorted = [..._mistakes]..sort((a, b) => b.timesObserved.compareTo(a.timesObserved));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.take(5).map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('• ${m.pattern} (seen ${m.timesObserved}×)',
                style: theme.textTheme.bodySmall),
          )).toList(),
    );
  }

  Widget _buildGoalSummary(ThemeData theme) {
    if (_roadmap == null) {
      return AppActionCard(
        icon: Icons.flag_outlined,
        title: 'No learning goal set',
        subtitle: 'Set a goal to generate your personalized roadmap',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const GoalSelectorScreen())),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target: ${_roadmap!.targetLevel}',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Reassess: ${_roadmap!.reassessmentSchedule}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          ..._roadmap!.priorities.take(3).map((p) => Text('• $p', style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
