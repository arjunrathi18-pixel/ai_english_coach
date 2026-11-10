import 'package:flutter/material.dart';
import 'daily_challenge_screen.dart';
import 'roleplay_setup_screen.dart';
import 'interview_setup_screen.dart';
import 'meeting_screen.dart';
import 'email_coach_screen.dart';
import 'presentation_screen.dart';
import 'debate_screen.dart';
import 'travel_hub_screen.dart';
import 'fluency_lab_screen.dart';
import 'think_in_english_screen.dart';
import 'listening_screen.dart';
import 'pronunciation_hub_screen.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class PracticeTab extends StatelessWidget {
  const PracticeTab({super.key});

  void _go(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: AppSpacing.md);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppActionCard(icon: Icons.bolt, title: 'Daily Challenge', subtitle: 'A quick practice for the time you have', onTap: () => _go(context, const DailyChallengeScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Real-life'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.theater_comedy_outlined, title: 'Roleplay', subtitle: 'Restaurant, shopping, calls and more', onTap: () => _go(context, const RoleplaySetupScreen())),
          gap(),
          AppActionCard(icon: Icons.flight_takeoff_outlined, title: 'Travel English', subtitle: 'Phrase kits for airports, hotels, directions', onTap: () => _go(context, const TravelHubScreen())),
          gap(),
          AppActionCard(icon: Icons.work_outline, title: 'Interview Simulator', subtitle: 'Realistic mock interviews with a report', onTap: () => _go(context, const InterviewSetupScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Work & Business'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.groups_outlined, title: 'Meeting Simulator', subtitle: 'Run a workplace meeting, get action items', onTap: () => _go(context, const MeetingScreen())),
          gap(),
          AppActionCard(icon: Icons.email_outlined, title: 'Email Coach', subtitle: 'Draft or improve professional emails', onTap: () => _go(context, const EmailCoachScreen())),
          gap(),
          AppActionCard(icon: Icons.campaign_outlined, title: 'Presentation Practice', subtitle: 'Outline, deliver, handle Q&A', onTap: () => _go(context, const PresentationScreen())),
          gap(),
          AppActionCard(icon: Icons.forum_outlined, title: 'Debate Practice', subtitle: 'Argue a position against an AI opponent', onTap: () => _go(context, const DebateScreen())),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Speaking Skills'),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(icon: Icons.speed_outlined, title: 'Fluency Lab', subtitle: 'Rapid response, one-minute speaking, circumlocution', onTap: () => _go(context, const FluencyLabScreen())),
          gap(),
          AppActionCard(icon: Icons.lightbulb_outline, title: 'Think in English', subtitle: 'Stop translating, start thinking', onTap: () => _go(context, const ThinkInEnglishScreen())),
          gap(),
          AppActionCard(icon: Icons.hearing_outlined, title: 'Listening', subtitle: 'Listen, understand, respond', onTap: () => _go(context, const ListeningScreen())),
          gap(),
          AppActionCard(icon: Icons.graphic_eq, title: 'Pronunciation', subtitle: 'Shadowing, word practice, minimal pairs', onTap: () => _go(context, const PronunciationHubScreen())),
        ],
      ),
    );
  }
}
