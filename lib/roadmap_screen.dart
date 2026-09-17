import 'package:flutter/material.dart';

import 'curriculum.dart';
import 'curriculum_store.dart';
import 'daily_session.dart';
import 'learner_profile.dart';
import 'learning_engine_service.dart';
import 'profile_store.dart';
import 'chat_screen.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  LearningRoadmap? _roadmap;
  DailySessionPlan? _todaysSession;
  bool _loading = true;
  bool _generatingSession = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roadmap = await CurriculumStore.loadRoadmap();
    final cachedSession = await CurriculumStore.loadDailySession();
    setState(() {
      _roadmap = roadmap;
      _todaysSession =
          (cachedSession != null && !cachedSession.isStale) ? cachedSession : null;
      _loading = false;
    });
  }

  Future<void> _generateTodaysSession() async {
    if (_roadmap == null) return;
    final profile = await ProfileStore.load();
    final goal = await CurriculumStore.loadGoal();
    final mistakes = await CurriculumStore.loadMistakes();
    if (profile == null) return;

    setState(() => _generatingSession = true);
    final session = await LearningEngineService().generateDailySession(
      profile: profile,
      roadmap: _roadmap!,
      recentMistakes: mistakes,
      availableMinutesToday: goal?.dailyMinutesAvailable ?? _roadmap!.dailyPracticeMinutes,
    );
    setState(() => _generatingSession = false);

    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate today\'s session — try again.')),
      );
      return;
    }

    await CurriculumStore.saveDailySession(session);
    setState(() => _todaysSession = session);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_roadmap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Learning Plan')),
        body: const Center(child: Text('No plan yet — set a goal first.')),
      );
    }

    final roadmap = _roadmap!;
    return Scaffold(
      appBar: AppBar(title: const Text('My Learning Plan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _levelBadge('Current', roadmap.currentLevel),
              const Icon(Icons.arrow_forward, color: Colors.black38),
              _levelBadge('Target', roadmap.targetLevel),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Top priorities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...roadmap.priorities.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${e.key + 1}. ${e.value}'),
                ),
              ),
          const SizedBox(height: 24),
          Text(
            'Daily practice: ${roadmap.dailyPracticeMinutes} min  •  Reassess: ${roadmap.reassessmentSchedule}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text('Weekly plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...roadmap.weeks.map((w) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('Week ${w.weekNumber}: ${w.focus}'),
                  subtitle: Text(w.details),
                ),
              )),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          const Text("Today's Session",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_generatingSession)
            const Center(child: CircularProgressIndicator())
          else if (_todaysSession == null)
            FilledButton.icon(
              onPressed: _generateTodaysSession,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Today\'s Session'),
            )
          else
            _sessionCard(_todaysSession!),
        ],
      ),
    );
  }

  Widget _levelBadge(String label, String level) {
    return Column(
      children: [
        Text(level,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _sessionCard(DailySessionPlan session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.lessonType,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(session.objective),
          const SizedBox(height: 12),
          ...session.structure.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${p.phase} (${p.minutes} min): ${p.description}'),
              )),
          const SizedBox(height: 12),
          Text('Goal: ${session.dailyGoal}',
              style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    initialEstimatedLevel: session.level,
                    sessionPlan: session,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start This Session'),
          ),
        ],
      ),
    );
  }
}
