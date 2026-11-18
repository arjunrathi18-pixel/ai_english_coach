import 'package:flutter/material.dart';

import 'learner_profile.dart';
import 'learning_goal.dart';
import 'learning_engine_service.dart';
import 'curriculum_store.dart';
import 'profile_store.dart';
import 'roadmap_screen.dart';

class GoalSelectorScreen extends StatefulWidget {
  const GoalSelectorScreen({super.key});

  @override
  State<GoalSelectorScreen> createState() => _GoalSelectorScreenState();
}

class _GoalSelectorScreenState extends State<GoalSelectorScreen> {
  LearningGoal _primary = LearningGoal.generalSpeaking;
  LearningGoal? _secondary;
  double _minutes = 15;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What are you learning for?')),
      body: _generating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Building your personalized plan…'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Primary goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _goalGrid(
                  selected: _primary,
                  onSelect: (g) => setState(() => _primary = g),
                ),
                const SizedBox(height: 24),
                const Text('Secondary goal (optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _goalGrid(
                  selected: _secondary,
                  onSelect: (g) =>
                      setState(() => _secondary = g == _secondary ? null : g),
                ),
                const SizedBox(height: 24),
                Text('Daily practice time: ${_minutes.round()} minutes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Slider(
                  value: _minutes,
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '${_minutes.round()} min',
                  onChanged: (v) => setState(() => _minutes = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _onContinue,
                  child: const Text('Build My Learning Plan'),
                ),
              ],
            ),
    );
  }

  Widget _goalGrid({
    required LearningGoal? selected,
    required ValueChanged<LearningGoal> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LearningGoal.values.map((g) {
        return ChoiceChip(
          label: Text(g.label),
          selected: g == selected,
          onSelected: (_) => onSelect(g),
        );
      }).toList(),
    );
  }

  Future<void> _onContinue() async {
    final profile = await ProfileStore.load();
    if (profile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take the Level Assessment first.'),
        ),
      );
      return;
    }

    final goal = GoalSelection(
      primaryGoal: _primary,
      secondaryGoal: _secondary,
      dailyMinutesAvailable: _minutes.round(),
    );

    setState(() => _generating = true);
    await CurriculumStore.saveGoal(goal);

    final roadmap = await LearningEngineService().generateRoadmap(
      profile: profile,
      goal: goal,
    );

    setState(() => _generating = false);

    if (roadmap == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not build a plan right now — please try again.'),
        ),
      );
      return;
    }

    await CurriculumStore.saveRoadmap(roadmap);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoadmapScreen()),
    );
  }
}
