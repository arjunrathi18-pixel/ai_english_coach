import 'package:flutter/material.dart';
import 'shadowing_screen.dart';
import 'word_practice_screen.dart';
import 'minimal_pairs_screen.dart';

class PronunciationHubScreen extends StatelessWidget {
  const PronunciationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pronunciation Practice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _tile(
            context,
            icon: Icons.repeat,
            title: 'Shadowing',
            subtitle: 'Listen to a sentence, then repeat it back',
            builder: (_) => const ShadowingScreen(),
          ),
          _tile(
            context,
            icon: Icons.text_fields,
            title: 'Word Practice',
            subtitle: 'Look up any word: IPA, syllables, stress, and try it',
            builder: (_) => const WordPracticeScreen(),
          ),
          _tile(
            context,
            icon: Icons.compare_arrows,
            title: 'Minimal Pairs',
            subtitle: 'Practice tricky sound contrasts, e.g. ship vs sheep',
            builder: (_) => const MinimalPairsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}
