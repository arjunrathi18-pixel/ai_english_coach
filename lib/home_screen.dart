import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'ask_coach_screen.dart';
import 'api_key_screen.dart';
import 'api_key_store.dart';
import 'orchestrator_service.dart';
import 'orchestrator_router.dart';
import 'learner_profile.dart';
import 'curriculum.dart';
import 'gamification_models.dart';
import 'gamification_store.dart';
import 'profile_store.dart';
import 'curriculum_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Home tab: one clear next step (Prompt 20, section 136 — Smart Start),
/// not 30 equal options. Everything else lives in Practice / Learn / Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrchestratorService _orchestrator = OrchestratorService();
  LearnerProfile? _profile;
  LearningRoadmap? _roadmap;
  LearnerStats _stats = LearnerStats();
  NextBestAction? _next;
  bool _loading = true;
  bool _hasKey = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final profile = await ProfileStore.load();
    final roadmap = await CurriculumStore.loadRoadmap();
    final stats = await GamificationStore.load();
    final next = await _orchestrator.recommendNext();
    final hasKey = await ApiKeyStore.hasKey();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _roadmap = roadmap;
      _stats = stats;
      _next = next;
      _hasKey = hasKey;
      _loading = false;
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _loadState(); // refresh stats/recommendation after returning
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI English Coach')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadState,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  Text('$_greeting.',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Ready to speak English?',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: AppSpacing.lg),
                  if (!_hasKey) ...[
                    _buildKeyBanner(theme),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _buildStatsRow(theme),
                  const SizedBox(height: AppSpacing.xl),
                  _buildHero(theme),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionHeader(title: 'Recommended for you'),
                  const SizedBox(height: AppSpacing.md),
                  if (_next != null)
                    AppActionCard(
                      icon: Icons.auto_awesome,
                      title: _next!.title,
                      subtitle: _next!.subtitle,
                      onTap: () {
                        final screen = OrchestratorRouter.screenFor(_next!.intent);
                        if (screen != null) _push(screen);
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  AppActionCard(
                    icon: Icons.record_voice_over_outlined,
                    title: 'Ask your coach',
                    subtitle: 'Say what you want — "Teach me", "Interview practice"…',
                    onTap: () => _push(const AskCoachScreen()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKeyBanner(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () => _push(const ApiKeyScreen()),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            const Icon(Icons.key_outlined, color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'AI is not connected. Tap to add your API key — chat, roleplay and interviews need it.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(text, style: theme.textTheme.labelMedium),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('🔥 ${_stats.currentStreak} day streak'),
        chip('⭐ ${_stats.totalXp} XP'),
        chip('Lv ${_stats.level} · ${_stats.levelTitle}'),
      ],
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentPrimary, Color(0xFF4B45C9)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profile != null
                ? 'Level ${_profile!.overallLevel}${_roadmap != null ? ' → Target ${_roadmap!.targetLevel}' : ''}'
                : "Let's find your starting point",
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Let's improve your speaking fluency.",
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accentPrimary,
            ),
            onPressed: () => _push(ChatScreen(initialEstimatedLevel: _profile?.overallLevel)),
            icon: const Icon(Icons.mic),
            label: const Text('Start Speaking'),
          ),
        ],
      ),
    );
  }
}
