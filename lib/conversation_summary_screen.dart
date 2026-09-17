import 'package:flutter/material.dart';
import 'conversation_summary.dart';

class ConversationSummaryScreen extends StatelessWidget {
  final ConversationSummary summary;
  const ConversationSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card('💪 Strong Point', summary.strongPoint, Colors.green),
          const SizedBox(height: 12),
          _card('🎯 Main Improvement', summary.improvement, Colors.orange),
          const SizedBox(height: 12),
          _card('📌 Practice Recommendation', summary.recommendation, Colors.blue),
          const SizedBox(height: 24),
          if (summary.newExpressions.isNotEmpty) ...[
            const Text('New expressions you used',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.newExpressions
                  .map((e) => Chip(label: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (summary.wordsToReview.isNotEmpty) ...[
            const Text('Words to review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.wordsToReview
                  .map((e) => Chip(label: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (summary.topicsDiscussed.isNotEmpty) ...[
            const Text('Topics you discussed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(summary.topicsDiscussed.join(', ')),
            const SizedBox(height: 20),
          ],
          if (summary.corrections.isNotEmpty) ...[
            const Text('Corrections made this session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...summary.corrections.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const Text('•  '), Expanded(child: Text(c))],
                  ),
                )),
          ],
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
