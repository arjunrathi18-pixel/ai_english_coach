import 'package:flutter/material.dart';
import 'grammar_lab_screen.dart';
import 'vocabulary_screen.dart';
import 'say_it_better_screen.dart';
import 'my_mistakes_screen.dart';
import 'review_session_screen.dart';
import 'roadmap_screen.dart';
import 'assessment_screen.dart';
import 'goal_selector_screen.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  void _go(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: AppSpacing.md);
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SectionHeader(title: 'Skills'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.rule_outlined, title: 'Grammar Lab', subtitle: 'Topic-based drills with instant feedback', onTap: () => _go(context, const GrammarLabScreen())),
          gap(),
          AppActionCard(icon: Icons.menu_book_outlined, title: 'My Vocabulary', subtitle: 'Words, phrases and spaced review', onTap: () => _go(context, const VocabularyScreen())),
          gap(),
          AppActionCard(icon: Icons.auto_fix_high_outlined, title: 'Say It Better', subtitle: 'Make a sentence natural or professional', onTap: () => _go(context, const SayItBetterScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Review'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.replay_circle_filled_outlined, title: 'Review Session', subtitle: 'Revise what is due — words and mistakes', onTap: () => _go(context, const ReviewSessionScreen())),
          gap(),
          AppActionCard(icon: Icons.report_gmailerrorred_outlined, title: 'My Mistakes', subtitle: 'Patterns to fix, with micro-lessons', onTap: () => _go(context, const MyMistakesScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Your Plan'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.map_outlined, title: 'Learning Roadmap', subtitle: 'Your personalized plan and daily session', onTap: () => _go(context, const RoadmapScreen())),
          gap(),
          AppActionCard(icon: Icons.flag_outlined, title: 'Learning Goal', subtitle: 'Set or change what you are working toward', onTap: () => _go(context, const GoalSelectorScreen())),
          gap(),
          AppActionCard(icon: Icons.fact_check_outlined, title: 'Level Assessment', subtitle: 'Check your current level', onTap: () => _go(context, const AssessmentScreen())),
        ],
      ),
    );
  }
}
