import 'package:flutter/material.dart';
import 'progress_dashboard_screen.dart';
import 'achievements_screen.dart';
import 'learner_memory_screen.dart';
import 'voice_personality_settings_screen.dart';
import 'theme_controller.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _go(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: AppSpacing.md);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppActionCard(icon: Icons.insights_outlined, title: 'My Progress', subtitle: 'Level, skills, vocabulary, streak', onTap: () => _go(context, const ProgressDashboardScreen())),
          gap(),
          AppActionCard(icon: Icons.emoji_events_outlined, title: 'Achievements', subtitle: 'Badges earned through real practice', onTap: () => _go(context, const AchievementsScreen())),
          gap(),
          AppActionCard(icon: Icons.tune, title: 'Voice & Personality', subtitle: 'AI personality, accent, correction style', onTap: () => _go(context, const VoicePersonalitySettingsScreen())),
          gap(),
          AppActionCard(icon: Icons.psychology_alt_outlined, title: 'What I Remember', subtitle: 'See, edit or reset your learning data', onTap: () => _go(context, const LearnerMemoryScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: themeController,
            builder: (context, _) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ],
              selected: {themeController.mode},
              onSelectionChanged: (s) => themeController.setMode(s.first),
            ),
          ),
        ],
      ),
    );
  }
}
