import 'package:flutter/material.dart';
import 'presentation_debate_service.dart';
import 'presentation_debate_models.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

enum _Stage { setup, outline, delivering, qa, feedback }

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final PresentationDebateService _service = PresentationDebateService();
  final _topicController = TextEditingController();
  final _audienceController = TextEditingController();
  final _speechController = TextEditingController();
  final _qaAnswerController = TextEditingController();

  _Stage _stage = _Stage.setup;
  int _minutes = 3;
  PresentationOutline? _outline;
  final List<String> _qaLog = [];
  String? _currentQuestion;
  int _qaRound = 0;
  PresentationFeedback? _feedback;
  bool _loading = false;

  Future<void> _getOutline() async {
    if (_topicController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final outline = await _service.getOutline(
      topic: _topicController.text.trim(),
      audience: _audienceController.text.trim().isEmpty ? 'general audience' : _audienceController.text.trim(),
      minutes: _minutes,
    );
    setState(() {
      _outline = outline;
      _loading = false;
      if (outline != null) _stage = _Stage.outline;
    });
  }

  Future<void> _startQA() async {
    setState(() {
      _stage = _Stage.qa;
      _loading = true;
    });
    final q = await _service.getAudienceQuestion(presentationText: _speechController.text.trim(), previousQA: _qaLog);
    setState(() {
      _currentQuestion = q;
      _loading = false;
    });
  }

  Future<void> _answerQuestion() async {
    if (_currentQuestion == null || _qaAnswerController.text.trim().isEmpty) return;
    _qaLog.add('Q: $_currentQuestion\nA: ${_qaAnswerController.text.trim()}');
    _qaAnswerController.clear();
    _qaRound++;
    if (_qaRound >= 3) {
      await _finish();
      return;
    }
    setState(() => _loading = true);
    final q = await _service.getAudienceQuestion(presentationText: _speechController.text.trim(), previousQA: _qaLog);
    setState(() {
      _currentQuestion = q;
      _loading = false;
    });
  }

  Future<void> _finish() async {
    setState(() {
      _stage = _Stage.feedback;
      _loading = true;
    });
    final transcript = ['Presentation: ${_speechController.text.trim()}', ..._qaLog];
    final feedback = await _service.getPresentationFeedback(transcript);
    setState(() {
      _feedback = feedback;
      _loading = false;
    });
    if (feedback != null) await GamificationService.recordCompletion(xp: 25);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _audienceController.dispose();
    _speechController.dispose();
    _qaAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentation Practice')),
      body: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    switch (_stage) {
      case _Stage.setup:
        return ListView(
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _audienceController,
              decoration: const InputDecoration(labelText: 'Audience (optional)', hintText: 'e.g. "my manager"', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Duration: $_minutes min'),
            Slider(value: _minutes.toDouble(), min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _minutes = v.round())),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Build Outline', onPressed: _getOutline),
          ],
        );
      case _Stage.outline:
        return ListView(
          children: [
            Text(_outline!.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Opening: ${_outline!.opening}'),
            const SizedBox(height: AppSpacing.md),
            const Text('Main points:', style: TextStyle(fontWeight: FontWeight.w600)),
            ..._outline!.mainPoints.map((p) => Text('• $p')),
            const SizedBox(height: AppSpacing.md),
            Text('Conclusion: ${_outline!.conclusion}'),
            const SizedBox(height: AppSpacing.xl),
            const Text('Now write/speak your presentation using this outline:'),
            const SizedBox(height: 8),
            TextField(
              controller: _speechController,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Your presentation…', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Deliver & Get Q&A', onPressed: _startQA),
          ],
        );
      case _Stage.delivering:
        return const SizedBox.shrink();
      case _Stage.qa:
        return ListView(
          children: [
            Text('Audience Q&A (${_qaRound + 1}/3)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(_currentQuestion ?? '', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _qaAnswerController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Your answer…', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: _qaRound >= 2 ? 'Finish' : 'Next Question', onPressed: _answerQuestion),
          ],
        );
      case _Stage.feedback:
        if (_feedback == null) return const Center(child: Text('Could not generate feedback.'));
        return ListView(
          children: [
            _fbCard('Structure', _feedback!.structure, AppColors.accentPrimary),
            const SizedBox(height: 8),
            _fbCard('Clarity', _feedback!.clarity, AppColors.accentSecondary),
            const SizedBox(height: 8),
            _fbCard('Q&A Handling', _feedback!.qaHandling, AppColors.success),
            const SizedBox(height: 8),
            _fbCard('Main Improvement', _feedback!.mainImprovement, AppColors.warning),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to Home')),
          ],
        );
    }
  }

  Widget _fbCard(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.medium)),
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
