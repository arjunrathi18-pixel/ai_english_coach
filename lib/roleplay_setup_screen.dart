import 'package:flutter/material.dart';
import 'roleplay_categories.dart';
import 'roleplay_service.dart';
import 'roleplay_screen.dart';
import 'profile_store.dart';
import 'curriculum_store.dart';
import 'learning_goal.dart';

class RoleplaySetupScreen extends StatefulWidget {
  const RoleplaySetupScreen({super.key});

  @override
  State<RoleplaySetupScreen> createState() => _RoleplaySetupScreenState();
}

class _RoleplaySetupScreenState extends State<RoleplaySetupScreen> {
  final TextEditingController _customController = TextEditingController();
  final RoleplayService _service = RoleplayService();

  double _difficulty = 3;
  bool _generating = false;
  String _level = 'unknown';
  String _goal = 'general speaking';

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
    CurriculumStore.loadGoal().then((g) {
      if (g != null) setState(() => _goal = g.primaryGoal.label);
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _startScenario(String request) async {
    setState(() => _generating = true);
    final scenario = await _service.generateScenario(
      request: request,
      level: _level,
      goal: _goal,
      difficultyLevel: _difficulty.round(),
    );
    setState(() => _generating = false);

    if (scenario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not build that scenario — try again.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoleplayScreen(scenario: scenario)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_generating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting the scene…'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Roleplay Practice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Difficulty: ${_difficulty.round()} / 6',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _difficulty,
            min: 1,
            max: 6,
            divisions: 5,
            label: '${_difficulty.round()}',
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 12),
          const Text('Describe your own scenario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. "Practice asking my manager for a raise"',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => v.trim().isEmpty ? null : _startScenario(v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final text = _customController.text.trim();
                  if (text.isNotEmpty) _startScenario(text);
                },
                child: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Or pick a scenario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...kRoleplayCategories.entries.map((entry) => ExpansionTile(
                title: Text(entry.key),
                children: entry.value
                    .map((title) => ListTile(
                          title: Text(title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _startScenario('${entry.key} > $title'),
                        ))
                    .toList(),
              )),
        ],
      ),
    );
  }
}
