import 'package:flutter/material.dart';
import 'presentation_screen.dart';
import 'debate_screen.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class PresentationDebateStudioScreen extends StatelessWidget {
  const PresentationDebateStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentation & Debate')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppActionCard(
            icon: Icons.campaign_outlined,
            title: 'Presentation Practice',
            subtitle: 'Build an outline, deliver it, and handle audience Q&A',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PresentationScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(
            icon: Icons.forum_outlined,
            title: 'Debate Practice',
            subtitle: 'Argue a position against a genuine AI opponent',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DebateScreen())),
          ),
        ],
      ),
    );
  }
}
