import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'assessment_screen.dart';
import 'goal_selector_screen.dart';
import 'roadmap_screen.dart';
import 'say_it_better_screen.dart';
import 'my_mistakes_screen.dart';
import 'pronunciation_hub_screen.dart';
import 'vocabulary_screen.dart';
import 'listening_screen.dart';
import 'roleplay_setup_screen.dart';
import 'learner_profile.dart';
import 'curriculum.dart';
import 'profile_store.dart';
import 'curriculum_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LearnerProfile? _profile;
  LearningRoadmap? _roadmap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final profile = await ProfileStore.load();
    final roadmap = await CurriculumStore.loadRoadmap();
    setState(() {
      _profile = profile;
      _roadmap = roadmap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI English Coach'),
        actions: [
          IconButton(
            tooltip: 'Say It Better',
            icon: const Icon(Icons.auto_fix_high_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SayItBetterScreen()),
            ),
          ),
          IconButton(
            tooltip: 'My Mistakes',
            icon: const Icon(Icons.checklist_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyMistakesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'My Vocabulary',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VocabularyScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.record_voice_over, size: 72, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Learn English. Think English. Speak English.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (!_loading && _profile != null)
                Text(
                  'Your level: ${_profile!.overallLevel}'
                  '${_roadmap != null ? "  →  Target: ${_roadmap!.targetLevel}" : ""}',
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        initialEstimatedLevel: _profile?.overallLevel,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Start Speaking'),
              ),
              const SizedBox(height: 12),
              if (_roadmap != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoadmapScreen()),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('My Learning Plan'),
                )
              else if (_profile != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GoalSelectorScreen()),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Set My Learning Goal'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RoleplaySetupScreen()),
                  );
                },
                icon: const Icon(Icons.theater_comedy_outlined),
                label: const Text('Roleplay Practice'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ListeningScreen()),
                  );
                },
                icon: const Icon(Icons.headphones_outlined),
                label: const Text('Listening Practice'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PronunciationHubScreen()),
                  );
                },
                icon: const Icon(Icons.record_voice_over_outlined),
                label: const Text('Pronunciation Practice'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(_profile == null
                    ? 'Take Level Assessment'
                    : 'Retake Level Assessment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
