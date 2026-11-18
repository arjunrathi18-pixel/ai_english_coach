import 'package:flutter/material.dart';
import 'business_models.dart';
import 'design_tokens.dart';
import 'gamification_service.dart';

class MeetingSummaryScreen extends StatefulWidget {
  final MeetingSummary summary;
  const MeetingSummaryScreen({super.key, required this.summary});

  @override
  State<MeetingSummaryScreen> createState() => _MeetingSummaryScreenState();
}

class _MeetingSummaryScreenState extends State<MeetingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    GamificationService.recordCompletion(xp: 25);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Summary')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Key Points', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...s.keyPoints.map((p) => Text('• $p')),
          const SizedBox(height: AppSpacing.xl),
          Text('Decisions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (s.decisions.isEmpty) const Text('No formal decisions were made.'),
          ...s.decisions.map((d) => Text('• $d')),
          const SizedBox(height: AppSpacing.xl),
          Text('Action Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (s.actionItems.isEmpty) const Text('No action items captured.'),
          ...s.actionItems.map((a) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(a.item),
                  subtitle: Text('${a.owner} — due ${a.deadline}'),
                ),
              )),
          if (s.openQuestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Open Questions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...s.openQuestions.map((q) => Text('• $q')),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(s.communicationFeedback),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
