import 'package:flutter/material.dart';
import 'daily_challenge_service.dart';
import 'daily_challenge_models.dart';
import 'daily_session.dart';
import 'chat_screen.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final DailyChallengeService _service = DailyChallengeService();
  int _minutes = 10;
  DailyChallenge? _challenge;
  bool _loading = false;
  bool _failed = false;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final c = await _service.generate(minutes: _minutes);
    setState(() {
      _challenge = c;
      _loading = false;
      _failed = c == null;
    });
  }

  Future<void> _start() async {
    final c = _challenge!;
    final profile = await ProfileStore.load();
    if (!mounted) return;
    final plan = DailySessionPlan(
      lessonType: c.title,
      level: profile?.overallLevel ?? 'unknown',
      objective: c.objective,
      structure: [],
      dailyGoal: c.dailyGoal,
      totalMinutes: _minutes,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        initialEstimatedLevel: profile?.overallLevel,
        sessionPlan: plan,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('How much time do you have?', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 5, 10, 15, 30, 60].map((m) => ChoiceChip(
                  label: Text('$m min'),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() => _minutes = m),
                )).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _challenge == null ? 'Get Today\'s Challenge' : 'New Challenge',
            loading: _loading,
            onPressed: _generate,
          ),
          if (_failed) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('Could not generate a challenge. Please try again.'),
          ],
          if (_challenge != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_challenge!.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_challenge!.why,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Goal: ${_challenge!.dailyGoal}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.md),
                  ..._challenge!.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${e.key + 1}. ${e.value}'),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Start Challenge', icon: Icons.play_arrow, onPressed: _start),
          ],
        ],
      ),
    );
  }
}
