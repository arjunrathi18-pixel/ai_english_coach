import 'package:flutter/material.dart';
import 'grammar_prompts.dart';
import 'grammar_models.dart';
import 'grammar_service.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

class GrammarLabScreen extends StatefulWidget {
  const GrammarLabScreen({super.key});

  @override
  State<GrammarLabScreen> createState() => _GrammarLabScreenState();
}

class _GrammarLabScreenState extends State<GrammarLabScreen> {
  final GrammarService _service = GrammarService();
  final _answerController = TextEditingController();

  String? _topic;
  GrammarDrill? _drill;
  GrammarEvalResult? _result;
  bool _loading = false;
  bool _checking = false;
  int _correctInSession = 0;
  int _attemptsInSession = 0;
  String _level = 'unknown';

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
    super.dispose();
  }

  Future<void> _pickTopic(String topic) async {
    setState(() {
      _topic = topic;
      _correctInSession = 0;
      _attemptsInSession = 0;
    });
    await _nextDrill();
  }

  Future<void> _nextDrill() async {
    if (_topic == null) return;
    setState(() {
      _loading = true;
      _drill = null;
      _result = null;
      _answerController.clear();
    });
    final drill = await _service.generateDrill(topic: _topic!, level: _level);
    setState(() {
      _drill = drill;
      _loading = false;
    });
  }

  Future<void> _check() async {
    if (_drill == null || _answerController.text.trim().isEmpty) return;
    setState(() => _checking = true);
    final result = await _service.evaluate(drill: _drill!, learnerAnswer: _answerController.text.trim());
    setState(() {
      _checking = false;
      _result = result;
      if (result != null) {
        _attemptsInSession++;
        if (result.correct) {
          _correctInSession++;
          GamificationService.recordCompletion(xp: 8);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grammar Lab')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Pick a topic to practice', style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            ...kGrammarTopics.map((t) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(title: Text(t), onTap: () => _pickTopic(t)),
                )),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_topic!),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Center(child: Text('$_correctInSession/$_attemptsInSession')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _drill == null
                ? const Center(child: Text('Could not generate a drill.'))
                : ListView(
                    children: [
                      Text(_drill!.instruction, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text(_drill!.prompt, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _answerController,
                        decoration: const InputDecoration(hintText: 'Your answer…', border: OutlineInputBorder()),
                        onSubmitted: (_) => _check(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(label: 'Check', onPressed: _check, loading: _checking),
                      if (_result != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: (_result!.correct ? AppColors.success : AppColors.warning).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_result!.correct ? 'Correct!' : 'Not quite',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _result!.correct ? AppColors.success : AppColors.warning)),
                              const SizedBox(height: 4),
                              Text('Answer: ${_result!.correctAnswer}'),
                              const SizedBox(height: 4),
                              Text(_result!.explanation),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SecondaryButton(label: 'Next Drill', onPressed: _nextDrill),
                      ],
                    ],
                  ),
      ),
    );
  }
}
