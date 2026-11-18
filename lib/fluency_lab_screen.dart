import 'dart:async';
import 'package:flutter/material.dart';
import 'fluency_service.dart';
import 'fluency_models.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

enum _FluencyMode { none, rapid, oneMinute, circumlocution }

class FluencyLabScreen extends StatefulWidget {
  const FluencyLabScreen({super.key});

  @override
  State<FluencyLabScreen> createState() => _FluencyLabScreenState();
}

class _FluencyLabScreenState extends State<FluencyLabScreen> {
  final FluencyService _service = FluencyService();
  final _answerController = TextEditingController();
  _FluencyMode _mode = _FluencyMode.none;
  String _level = 'unknown';
  bool _loading = false;

  // Rapid response state
  String? _rapidQuestion;
  DateTime? _questionShownAt;
  String? _rapidFeedback;

  // One-minute speaking state
  String? _topic;
  OneMinuteFeedback? _oneMinuteFeedback;
  int _secondsLeft = 60;
  Timer? _timer;

  // Circumlocution state
  String? _target;
  CircumlocutionEval? _circumlocutionEval;

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _selectMode(_FluencyMode mode) async {
    setState(() {
      _mode = mode;
      _answerController.clear();
      _rapidFeedback = null;
      _oneMinuteFeedback = null;
      _circumlocutionEval = null;
    });
    if (mode == _FluencyMode.rapid) await _loadRapidQuestion();
    if (mode == _FluencyMode.oneMinute) await _loadTopic();
    if (mode == _FluencyMode.circumlocution) await _loadTarget();
  }

  Future<void> _loadRapidQuestion() async {
    setState(() => _loading = true);
    final q = await _service.getRapidQuestion(_level);
    setState(() {
      _rapidQuestion = q;
      _questionShownAt = DateTime.now();
      _loading = false;
    });
  }

  Future<void> _submitRapid() async {
    if (_rapidQuestion == null || _answerController.text.trim().isEmpty) return;
    final elapsed = DateTime.now().difference(_questionShownAt!).inSeconds;
    setState(() => _loading = true);
    final feedback = await _service.getRapidFeedback(
      question: _rapidQuestion!,
      answer: _answerController.text.trim(),
      elapsedSeconds: elapsed,
    );
    setState(() {
      _rapidFeedback = feedback;
      _loading = false;
    });
    if (feedback != null) await GamificationService.recordCompletion(xp: 8);
  }

  Future<void> _loadTopic() async {
    setState(() {
      _loading = true;
      _secondsLeft = 60;
    });
    final t = await _service.getSpeakingTopic(_level);
    setState(() {
      _topic = t;
      _loading = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submitOneMinute() async {
    if (_topic == null || _answerController.text.trim().isEmpty) return;
    _timer?.cancel();
    setState(() => _loading = true);
    final feedback = await _service.getOneMinuteFeedback(topic: _topic!, response: _answerController.text.trim());
    setState(() {
      _oneMinuteFeedback = feedback;
      _loading = false;
    });
    if (feedback != null) await GamificationService.recordCompletion(xp: 15);
  }

  Future<void> _loadTarget() async {
    setState(() => _loading = true);
    final w = await _service.getCircumlocutionTarget(_level);
    setState(() {
      _target = w;
      _loading = false;
    });
  }

  Future<void> _submitCircumlocution() async {
    if (_target == null || _answerController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final eval = await _service.evaluateCircumlocution(target: _target!, description: _answerController.text.trim());
    setState(() {
      _circumlocutionEval = eval;
      _loading = false;
    });
    if (eval != null) await GamificationService.recordCompletion(xp: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluency Lab')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _mode == _FluencyMode.none ? _buildModePicker() : _buildModeBody(),
      ),
    );
  }

  Widget _buildModePicker() {
    return ListView(
      children: [
        AppActionCard(
          icon: Icons.bolt_outlined,
          title: 'Rapid Response',
          subtitle: 'Quick questions — answer without over-preparing',
          onTap: () => _selectMode(_FluencyMode.rapid),
        ),
        const SizedBox(height: AppSpacing.md),
        AppActionCard(
          icon: Icons.timer_outlined,
          title: 'One-Minute Speaking',
          subtitle: 'Speak continuously on a topic for about a minute',
          onTap: () => _selectMode(_FluencyMode.oneMinute),
        ),
        const SizedBox(height: AppSpacing.md),
        AppActionCard(
          icon: Icons.psychology_outlined,
          title: 'Circumlocution Training',
          subtitle: 'Describe a word without saying it — a real-world skill',
          onTap: () => _selectMode(_FluencyMode.circumlocution),
        ),
      ],
    );
  }

  Widget _buildModeBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    switch (_mode) {
      case _FluencyMode.rapid:
        return _buildRapid();
      case _FluencyMode.oneMinute:
        return _buildOneMinute();
      case _FluencyMode.circumlocution:
        return _buildCircumlocution();
      case _FluencyMode.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRapid() {
    return ListView(
      children: [
        Text(_rapidQuestion ?? '', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _answerController,
          decoration: const InputDecoration(hintText: 'Your answer…', border: OutlineInputBorder()),
          onSubmitted: (_) => _submitRapid(),
          enabled: _rapidFeedback == null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_rapidFeedback == null)
          PrimaryButton(label: 'Submit', onPressed: _submitRapid)
        else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.accentPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.medium)),
            child: Text(_rapidFeedback!),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Next Question', onPressed: () => _selectMode(_FluencyMode.rapid)),
        ],
      ],
    );
  }

  Widget _buildOneMinute() {
    return ListView(
      children: [
        Text(_topic ?? '', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('$_secondsLeft s', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(width: AppSpacing.md),
            if (_oneMinuteFeedback == null)
              OutlinedButton(onPressed: _startTimer, child: const Text('Start Timer')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _answerController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Speak your response, then type a summary here…', border: OutlineInputBorder()),
          enabled: _oneMinuteFeedback == null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_oneMinuteFeedback == null)
          PrimaryButton(label: 'Submit', onPressed: _submitOneMinute)
        else ...[
          _feedbackCard('Strength', _oneMinuteFeedback!.strength, AppColors.success),
          const SizedBox(height: 8),
          _feedbackCard('Main Issue', _oneMinuteFeedback!.mainIssue, AppColors.warning),
          const SizedBox(height: 8),
          _feedbackCard('Practice Tip', _oneMinuteFeedback!.practiceTip, AppColors.accentPrimary),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'New Topic', onPressed: () => _selectMode(_FluencyMode.oneMinute)),
        ],
      ],
    );
  }

  Widget _buildCircumlocution() {
    return ListView(
      children: [
        Text('Describe this word without saying it:', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(_target ?? '', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _answerController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Your description…', border: OutlineInputBorder()),
          enabled: _circumlocutionEval == null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_circumlocutionEval == null)
          PrimaryButton(label: 'Check', onPressed: _submitCircumlocution)
        else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (_circumlocutionEval!.wouldGuessCorrectly ? AppColors.success : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(_circumlocutionEval!.feedback),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'New Word', onPressed: () => _selectMode(_FluencyMode.circumlocution)),
        ],
      ],
    );
  }

  Widget _feedbackCard(String title, String body, Color color) {
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
