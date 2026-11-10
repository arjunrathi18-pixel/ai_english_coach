import 'package:flutter/material.dart';
import 'meeting_screen.dart';
import 'email_coach_screen.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class BusinessHubScreen extends StatelessWidget {
  const BusinessHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Office & Business English')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppActionCard(
            icon: Icons.groups_outlined,
            title: 'Meeting Simulator',
            subtitle: 'Run a realistic workplace meeting and get a structured summary',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MeetingScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          AppActionCard(
            icon: Icons.email_outlined,
            title: 'Email Coach',
            subtitle: 'Draft a professional email, or get your own draft improved',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmailCoachScreen())),
          ),
        ],
      ),
    );
  }
}
