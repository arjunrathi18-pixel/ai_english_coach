import 'package:flutter/material.dart';
import 'orchestrator_service.dart';
import 'orchestrator_router.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// The learner can simply say what they want ("Talk to me", "Teach me",
/// "I have an interview tomorrow", "Surprise me") and the Orchestrator
/// opens the right experience. Explicit requests always win.
class AskCoachScreen extends StatefulWidget {
  const AskCoachScreen({super.key});

  @override
  State<AskCoachScreen> createState() => _AskCoachScreenState();
}

class _AskCoachScreenState extends State<AskCoachScreen> {
  final OrchestratorService _service = OrchestratorService();
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  static const _examples = [
    'Talk to me',
    'Teach me something',
    'I have an interview tomorrow',
    'I need English for work',
    "I don't know what to practice",
    'Surprise me',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final lower = t.toLowerCase();
    String intent;
    String reply = '';
    if (lower == 'surprise me' || lower.contains("don't know what to practice") || lower.contains('dont know what to practice')) {
      final next = await _service.recommendNext();
      intent = next.intent;
      reply = '${next.title} — ${next.subtitle}';
    } else {
      final decision = await _service.route(t);
      if (decision == null) {
        setState(() {
          _loading = false;
          _message = 'I could not understand that. Try again in a different way.';
        });
        return;
      }
      intent = decision.intent;
      reply = decision.reply;
    }

    final screen = OrchestratorRouter.screenFor(intent);
    setState(() {
      _loading = false;
      _message = reply;
    });
    if (screen != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Your Coach')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Tell me what you want to do. I will take you there.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'e.g. "Teach me present perfect"',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () => _submit(_controller.text)),
            ),
            onSubmitted: _submit,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_message != null && !_loading)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(_message!),
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Try saying'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _examples
                .map((e) => ActionChip(label: Text(e), onPressed: () {
                      _controller.text = e;
                      _submit(e);
                    }))
                .toList(),
          ),
        ],
      ),
    );
  }
}
