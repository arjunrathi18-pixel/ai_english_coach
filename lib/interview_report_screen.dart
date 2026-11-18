import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'interview_models.dart';
import 'conversation_summary_service.dart';
import 'gamification_service.dart';

class InterviewReportScreen extends StatefulWidget {
  final InterviewReport report;
  const InterviewReportScreen({super.key, required this.report});

  @override
  State<InterviewReportScreen> createState() => _InterviewReportScreenState();
}

class _InterviewReportScreenState extends State<InterviewReportScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.report.recurringIssues.isNotEmpty) {
      ConversationSummaryService().saveRecurringMistakes(widget.report.recurringIssues);
    }
    GamificationService.recordCompletion(xp: 30);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(r.overallPerformance,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _listSection('💪 Strong Areas', r.strongAreas, AppColors.success),
          const SizedBox(height: 16),
          _listSection('🎯 Areas to Improve', r.areasToImprove, AppColors.warning),
          const SizedBox(height: 20),
          const Text('English', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...r.englishNotes.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${_cap(e.key)}: ${e.value}'),
              )),
          const SizedBox(height: 20),
          const Text('Interview Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...r.interviewSkillNotes.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${_cap(e.key)}: ${e.value}'),
              )),
          const SizedBox(height: 20),
          _card('📌 Most Important Improvement', r.mostImportantImprovement, AppColors.accentPrimary),
          const SizedBox(height: 16),
          const Text('Best Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Q: ${r.bestAnswer.question}', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('A: ${r.bestAnswer.answer}'),
          const SizedBox(height: 20),
          const Text('Answer Needing Improvement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Q: ${r.answerNeedingImprovement.question}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('Original: ${r.answerNeedingImprovement.answer}'),
          const SizedBox(height: 6),
          Text('Improved: ${r.improvedVersion}',
              style: const TextStyle(color: AppColors.success)),
          const SizedBox(height: 20),
          const Text('Recommended Practice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...r.recommendedPractice.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${e.key + 1}. ${e.value}'),
              )),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _listSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $i'),
            )),
      ],
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
