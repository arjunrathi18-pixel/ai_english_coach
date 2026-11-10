import 'package:flutter/material.dart';
import 'think_prompts.dart';
import 'think_service.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

class ThinkInEnglishScreen extends StatefulWidget {
  const ThinkInEnglishScreen({super.key});

  @override
  State<ThinkInEnglishScreen> createState() => _ThinkInEnglishScreenState();
}

class _ThinkInEnglishScreenState extends State<ThinkInEnglishScreen> {
  final ThinkService _service = ThinkService();
  final _controller = TextEditingController();
  String _level = 'unknown';
  String? _mission;
  ThinkFeedback? _feedback;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_mission == null || _controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final fb = await _service.getFeedback(
      mission: _mission!,
      response: _controller.text.trim(),
      level: _level,
    );
    setState(() {
      _feedback = fb;
      _loading = false;
    });
    if (fb != null) await GamificationService.recordCompletion(xp: 10);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Think in English'),
        leading: _mission == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _mission = null;
                  _feedback = null;
                  _controller.clear();
                }),
              ),
      ),
      body: _mission == null
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text('Pick a mission. Think it in English first, then write or say it.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                ...kThinkMissions.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppActionCard(
                        icon: Icons.lightbulb_outline,
                        title: m,
                        subtitle: 'Tap to start',
                        onTap: () => setState(() => _mission = m),
                      ),
                    )),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(_mission!, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _controller,
                  maxLines: 6,
                  enabled: _feedback == null,
                  decoration: const InputDecoration(
                    hintText: 'Your English thoughts…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_feedback == null)
                  PrimaryButton(label: 'Get Feedback', loading: _loading, onPressed: _submit)
                else ...[
                  _card('What worked', _feedback!.strength, AppColors.success),
                  if (_feedback!.gentleNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _card('Something to notice', _feedback!.gentleNote, AppColors.warning),
                  ],
                  const SizedBox(height: 8),
                  _card('Next step', _feedback!.nextStep, AppColors.accentPrimary),
                  const SizedBox(height: AppSpacing.lg),
                  SecondaryButton(
                    label: 'Another Mission',
                    onPressed: () => setState(() {
                      _mission = null;
                      _feedback = null;
                      _controller.clear();
                    }),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _card(String title, String body, Color color) {
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
