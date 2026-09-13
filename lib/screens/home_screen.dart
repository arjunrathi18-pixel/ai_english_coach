import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'assessment_screen.dart';
import 'learner_profile.dart';
import 'profile_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LearnerProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStore.load();
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI English Coach')),
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
                  'Your level: ${_profile!.overallLevel}',
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
