import 'package:flutter/material.dart';
import 'learner_profile.dart';
import 'chat_screen.dart';

class AssessmentResultScreen extends StatelessWidget {
  final LearnerProfile profile;
  const AssessmentResultScreen({super.key, required this.profile});

  static const _skillLabels = {
    'speaking': 'Speaking',
    'grammar': 'Grammar',
    'vocabulary': 'Vocabulary',
    'fluency': 'Fluency',
    'pronunciation': 'Pronunciation',
    'listening': 'Listening',
    'comprehension': 'Comprehension',
    'naturalCommunication': 'Natural Communication',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your English Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  profile.overallLevel,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Text('Overall English Level',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Assessment confidence: ${profile.confidence}%',
                    style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Skill Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...profile.skills.entries.map((entry) {
            final label = _skillLabels[entry.key] ?? entry.key;
            final skill = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 150, child: Text(label)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: skill.score / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 32,
                    child: Text(skill.level,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          _infoCard('Main Strength', profile.mainStrength, Colors.green),
          const SizedBox(height: 10),
          _infoCard('Main Focus Area', profile.mainWeakness, Colors.orange),
          const SizedBox(height: 20),
          const Text('Recurring things to work on',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...profile.recurringIssues.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(i)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          const Text('Recommended starting point',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(profile.recommendedStartingPoint),
          const SizedBox(height: 20),
          const Text('First learning priorities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...profile.firstPriorities.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${e.key + 1}. ${e.value}'),
              )),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(initialEstimatedLevel: profile.overallLevel),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Practicing'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
