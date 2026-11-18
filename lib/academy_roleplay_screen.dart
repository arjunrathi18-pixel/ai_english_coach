import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'academy_speak_sheet.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// OFFLINE GUIDED ROLEPLAY — scripted dialogues you rehearse step by step.
/// This is NOT an AI conversation: the other person's lines are fixed.
class AcademyRoleplayScreen extends StatefulWidget {
  const AcademyRoleplayScreen({super.key});

  @override
  State<AcademyRoleplayScreen> createState() => _AcademyRoleplayScreenState();
}

class _AcademyRoleplayScreenState extends State<AcademyRoleplayScreen> {
  final _timer = Stopwatch()..start();
  AcademyProgress? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AcademyProgressStore.load();
    if (mounted) setState(() => _p = p);
  }

  @override
  void dispose() {
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Roleplay (guided, offline)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              'Offline guided roleplay: scripted practice with fixed lines. For free-flowing AI roleplay, use Practice > Roleplay when AI is connected.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...AcademyRepository.roleplays.map((r) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(_p?.roleplayDone.contains(r.id) ?? false ? Icons.check_circle : Icons.theater_comedy_outlined,
                      color: _p?.roleplayDone.contains(r.id) ?? false ? AppColors.success : null),
                  title: Text(r.title),
                  subtitle: Text('${r.category} · ${r.level} · you: ${r.userRole}'),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _RoleplayRun(scenario: r)));
                    _load();
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _RoleplayRun extends StatefulWidget {
  final RoleplayScenario scenario;
  const _RoleplayRun({required this.scenario});

  @override
  State<_RoleplayRun> createState() => _RoleplayRunState();
}

class _RoleplayRunState extends State<_RoleplayRun> {
  final SpeechService _speech = SpeechService();
  int _step = 0;
  bool _hintShown = false;

  RoleplayScenario get _s => widget.scenario;
  bool get _finished => _step >= _s.dialogue.length;

  @override
  void initState() {
    super.initState();
    _advanceAuto();
  }

  /// The other person's lines are shown and spoken automatically;
  /// the learner's lines wait for the learner.
  void _advanceAuto() {
    while (_step < _s.dialogue.length && !_s.dialogue[_step].isMe) {
      final line = _s.dialogue[_step];
      _speech.speak(line.en);
      _step++;
      break;
    }
  }

  @override
  void dispose() {
    _speech.stopSpeaking();
    super.dispose();
  }

  Future<void> _complete() async {
    await AcademyProgressStore.update((p) {
      p.roleplayDone.add(_s.id);
      p.touch();
    });
  }

  void _doneMyLine() {
    setState(() {
      _step++;
      _hintShown = false;
    });
    if (_step < _s.dialogue.length && !_s.dialogue[_step].isMe) {
      _speech.speak(_s.dialogue[_step].en);
      _step++;
      setState(() {});
    }
    if (_finished) _complete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = _s.dialogue.take(_step).toList();
    final current = _step < _s.dialogue.length ? _s.dialogue[_step] : null;
    return Scaffold(
      appBar: AppBar(title: Text(_s.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(_s.situation, style: theme.textTheme.bodyMedium),
          Text('You: ${_s.userRole} · Other person: ${_s.otherRole}', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ...shown.map((l) => Align(
                alignment: l.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: l.isMe ? AppColors.accentPrimary : theme.cardTheme.color,
                    border: l.isMe ? null : Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.en, style: TextStyle(color: l.isMe ? Colors.white : null, fontWeight: FontWeight.w600)),
                      Text(l.hi, style: TextStyle(color: l.isMe ? Colors.white70 : Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.lg),
          if (current != null && current.isMe) ...[
            Text('Your turn — say your line, then continue.', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Hint (Hindi): ${current.hi}', style: theme.textTheme.bodyMedium),
            if (_hintShown) ...[
              const SizedBox(height: 6),
              Text('Model line: ${current.en}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: _hintShown ? 'Hide model' : 'Show model', onPressed: () => setState(() => _hintShown = !_hintShown))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SecondaryButton(
                    label: 'Speak & compare',
                    icon: Icons.mic_none,
                    onPressed: () => SpeakCompareSheet.show(context, current.en, onAttempted: () {
                      AcademyProgressStore.update((p) => p.speakingDone.add('${_s.id}_$_step'));
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'I said it — continue', onPressed: _doneMyLine),
          ],
          if (_finished) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.medium)),
              child: Text('Scenario complete. Task: ${_s.task}', style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Useful vocabulary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ..._s.vocab.map((v) => Text('• ${v.word} — ${v.hindi}')),
            const SizedBox(height: AppSpacing.md),
            Text('Key phrases', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ..._s.phrases.map((p) => Text('• $p')),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Back to scenarios', onPressed: () => Navigator.of(context).pop()),
          ],
        ],
      ),
    );
  }
}
