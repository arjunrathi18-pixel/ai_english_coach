import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'academy_speak_sheet.dart';
import 'speech_service.dart';
import 'design_tokens.dart';

/// Daily English sentence library: English + Hindi, situation, level, an
/// alternative where useful, device text-to-speech, and speaking practice
/// with a transcript comparison (no pronunciation scores).
class AcademySentencesScreen extends StatefulWidget {
  const AcademySentencesScreen({super.key});

  @override
  State<AcademySentencesScreen> createState() => _AcademySentencesScreenState();
}

class _AcademySentencesScreenState extends State<AcademySentencesScreen> {
  final SpeechService _speech = SpeechService();
  final _search = TextEditingController();
  final _timer = Stopwatch()..start();
  AcademyProgress? _p;
  String? _situation;
  String? _level;

  @override
  void initState() {
    super.initState();
    AcademyProgressStore.load().then((p) {
      if (mounted) setState(() => _p = p);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _speech.stopSpeaking();
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  List<AcademySentence> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return AcademyRepository.sentences.where((s) {
      if (_situation != null && s.situation != _situation) return false;
      if (_level != null && s.level != _level) return false;
      if (q.isEmpty) return true;
      return s.en.toLowerCase().contains(q) || s.hi.contains(_search.text.trim()) || s.situation.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Sentences')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(hintText: 'Search sentences (English or Hindi)', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in AcademyRepository.sentenceSituations)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(s), selected: _situation == s, onSelected: (v) => setState(() => _situation = v ? s : null)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final l in const ['A1', 'A2', 'B1', 'B2'])
                ChoiceChip(label: Text(l), selected: _level == l, onSelected: (v) => setState(() => _level = v ? l : null)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${list.length} sentences', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          ...list.map((s) {
            final practised = _p?.speakingDone.contains(s.id) ?? false;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.en, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(s.hi, style: theme.textTheme.bodyMedium),
                    if (s.alt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Also: ${s.alt}', style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Text('${s.situation} · ${s.level}${practised ? ' · practised' : ''}', style: theme.textTheme.bodySmall)),
                        IconButton(icon: const Icon(Icons.volume_up_outlined), tooltip: 'Listen', onPressed: () => _speech.speak(s.en)),
                        IconButton(
                          icon: const Icon(Icons.mic_none),
                          tooltip: 'Practise speaking',
                          onPressed: () => SpeakCompareSheet.show(context, s.en, onAttempted: () async {
                            final p = await AcademyProgressStore.update((p) {
                              p.speakingDone.add(s.id);
                              p.touch();
                            });
                            if (mounted) setState(() => _p = p);
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
