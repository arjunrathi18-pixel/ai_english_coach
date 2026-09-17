import 'package:flutter/material.dart';
import 'roleplay_models.dart';
import 'conversation_summary_service.dart';

class RoleplayFeedbackScreen extends StatefulWidget {
  final RoleplayFeedback feedback;
  const RoleplayFeedbackScreen({super.key, required this.feedback});

  @override
  State<RoleplayFeedbackScreen> createState() => _RoleplayFeedbackScreenState();
}

class _RoleplayFeedbackScreenState extends State<RoleplayFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    // Feed recurring issues into the same shared mistake tracker the
    // Learning Engine (Prompt 3) and Friend Mode summaries (Prompt 4) use.
    if (widget.feedback.recurringIssues.isNotEmpty) {
      ConversationSummaryService().saveRecurringMistakes(widget.feedback.recurringIssues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feedback;
    return Scaffold(
      appBar: AppBar(title: const Text('Roleplay Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card('💪 Strength', f.strength, Colors.green),
          const SizedBox(height: 12),
          _card('🎯 Main Improvement', f.improvement, Colors.orange),
          if (f.naturalEnglishTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card('✨ Sound More Natural', f.naturalEnglishTip, Colors.blue),
          ],
          const SizedBox(height: 12),
          _card('📌 Next Practice', f.practiceRecommendation, Colors.indigo),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String body, Color color) {
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
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
