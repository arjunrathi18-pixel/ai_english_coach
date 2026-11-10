import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_personality.dart';
import 'conversation_length.dart';
import 'correction_intensity.dart';
import 'curriculum.dart';
import 'curriculum_store.dart';
import 'profile_store.dart';
import 'vocabulary_store.dart';
import 'voice_personality_store.dart';
import 'session_settings.dart';
import 'learner_profile.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// PROMPT 15 — Memory & Error Tracking, user-facing side (section 47):
/// the learner can SEE what the app remembers, remove an inaccurate
/// item, and reset categories. Distinct from Progress Dashboard, which
/// shows skill snapshots rather than what is stored.
class LearnerMemoryScreen extends StatefulWidget {
  const LearnerMemoryScreen({super.key});

  @override
  State<LearnerMemoryScreen> createState() => _LearnerMemoryScreenState();
}

class _LearnerMemoryScreenState extends State<LearnerMemoryScreen> {
  LearnerProfile? _profile;
  List<RecurringMistake> _mistakes = [];
  int _vocabCount = 0;
  SessionSettings? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileStore.load();
    final mistakes = await CurriculumStore.loadMistakes();
    final vocab = await VocabularyStore.loadAll();
    final prefs = await VoicePersonalityStore.loadDefaults();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _mistakes = mistakes;
      _vocabCount = vocab.length;
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _removeMistake(RecurringMistake m) async {
    final updated = _mistakes.where((x) => x.pattern != m.pattern).toList();
    await CurriculumStore.saveMistakes(updated);
    setState(() => _mistakes = updated);
  }

  Future<void> _resetMistakes() async {
    if (!await _confirm('Reset recurring mistakes?', 'This clears all tracked mistake patterns.')) return;
    await CurriculumStore.saveMistakes([]);
    await _load();
  }

  Future<void> _resetVocab() async {
    if (!await _confirm('Reset vocabulary progress?', 'All tracked words and mastery will be removed.')) return;
    await VocabularyStore.saveAll([]);
    await _load();
  }

  Future<void> _resetAll() async {
    if (!await _confirm('Reset everything?',
        'Profile, roadmap, mistakes, vocabulary, XP and streak will be erased. This cannot be undone.')) {
      return;
    }
    await ProfileStore.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      'learning_goal_v1',
      'learning_roadmap_v1',
      'daily_session_v1',
      'mastery_map_v1',
      'recurring_mistakes_v1',
      'vocabulary_profile_v1',
      'learner_stats_v1',
    ]) {
      await prefs.remove(k);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('What I Remember')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Only learning-related information is stored, on this device. You can remove anything here.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Level'),
                const SizedBox(height: 6),
                Text(_profile == null
                    ? 'Not assessed yet.'
                    : '${_profile!.overallLevel} (estimate, ${_profile!.confidence}% confidence)'),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Your Preferences'),
                const SizedBox(height: 6),
                if (_prefs != null) ...[
                  Text('Personality: ${_prefs!.personality.label}'),
                  Text('English variety: ${_prefs!.accent}'),
                  Text('Correction: ${_prefs!.correctionIntensity.label}'),
                  Text('Conversation length: ${_prefs!.conversationLength.label}'),
                ],
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Recurring Mistakes'),
                const SizedBox(height: 6),
                if (_mistakes.isEmpty)
                  const Text('None tracked.')
                else
                  ..._mistakes.map((m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.pattern),
                        subtitle: Text('Seen ${m.timesObserved}×'),
                        trailing: IconButton(
                          tooltip: 'Remove (not accurate)',
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeMistake(m),
                        ),
                      )),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Vocabulary'),
                const SizedBox(height: 6),
                Text('$_vocabCount words tracked'),
                const SizedBox(height: AppSpacing.xxxl),
                SecondaryButton(label: 'Reset mistakes', onPressed: _resetMistakes),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(label: 'Reset vocabulary', onPressed: _resetVocab),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(label: 'Reset everything', onPressed: _resetAll),
              ],
            ),
    );
  }
}
