import 'package:flutter/material.dart';
import 'academy_models.dart';
import 'academy_repository.dart';
import 'academy_progress_store.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Vocabulary: browse and search (works with inflected forms where the base
/// word is in the list), favorites, and spaced-repetition flashcards.
class AcademyVocabScreen extends StatefulWidget {
  final String? initialQuery;
  const AcademyVocabScreen({super.key, this.initialQuery});

  @override
  State<AcademyVocabScreen> createState() => _AcademyVocabScreenState();
}

class _AcademyVocabScreenState extends State<AcademyVocabScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final SpeechService _speech = SpeechService();
  final _search = TextEditingController();
  final _timer = Stopwatch()..start();
  AcademyProgress? _p;
  String? _category;
  String? _level;
  static const int _pageSize = 40;
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    if (widget.initialQuery != null) _search.text = widget.initialQuery!;
    AcademyProgressStore.load().then((p) {
      if (mounted) setState(() => _p = p);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _speech.stopSpeaking();
    AcademyProgressStore.addSeconds(_timer.elapsed.inSeconds);
    super.dispose();
  }

  Future<void> _toggleFav(AcademyWord w) async {
    final p = await AcademyProgressStore.update((p) {
      if (!p.favorites.add(w.word)) p.favorites.remove(w.word);
    });
    if (mounted) setState(() => _p = p);
  }

  void _openWord(AcademyWord w) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(w.word, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                  IconButton(icon: const Icon(Icons.volume_up_outlined), onPressed: () => _speech.speak(w.word)),
                ],
              ),
              Text('${w.pos} · ${w.level} · ${w.category}', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text('हिंदी: ${w.hindi}', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Meaning: ${w.meaning}', style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              Text('Example', style: theme.textTheme.labelLarge),
              Row(
                children: [
                  Expanded(child: Text(w.example, style: theme.textTheme.bodyLarge)),
                  IconButton(icon: const Icon(Icons.volume_up_outlined), onPressed: () => _speech.speak(w.example)),
                ],
              ),
              if (w.synonyms.isNotEmpty) Text('Synonyms: ${w.synonyms.join(', ')}', style: theme.textTheme.bodyMedium),
              if (w.antonyms.isNotEmpty) Text('Opposites: ${w.antonyms.join(', ')}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(AcademyWord w) {
    final fav = _p?.favorites.contains(w.word) ?? false;
    final box = _p?.srBox[w.word];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${w.hindi} · ${w.level}${box != null ? ' · box $box/5' : ''}'),
        trailing: IconButton(
          icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? AppColors.warning : null),
          onPressed: () => _toggleFav(w),
        ),
        onTap: () => _openWord(w),
      ),
    );
  }

  Widget _browse() {
    final theme = Theme.of(context);
    final all = AcademyRepository.searchWords(_search.text, category: _category, level: _level);
    final shown = all.take(_shown).toList();
    final note = AcademyRepository.lemmaNote(_search.text);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search English or Hindi (e.g. deadline, समय)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search.clear())),
          ),
          onChanged: (_) => setState(() => _shown = _pageSize),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in AcademyRepository.wordCategories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (v) => setState(() {
                      _category = v ? c : null;
                      _shown = _pageSize;
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final l in const ['A1', 'A2', 'B1', 'B2', 'C1'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l),
                    selected: _level == l,
                    onSelected: (v) => setState(() {
                      _level = v ? l : null;
                      _shown = _pageSize;
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('${all.length} words${note != null ? ' · $note' : ''}', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Not in the offline word list yet. The list is small and will grow with future content packs.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ...shown.map(_tile),
        if (all.length > shown.length)
          TextButton(onPressed: () => setState(() => _shown += _pageSize), child: const Text('Show more')),
      ],
    );
  }

  Widget _favorites() {
    final favs = AcademyRepository.words.where((w) => _p?.favorites.contains(w.word) ?? false).toList();
    if (favs.isEmpty) {
      return const AppEmptyState(icon: Icons.star_border, message: 'Tap the star on any word to save it here.');
    }
    return ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: favs.map(_tile).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Browse'), Tab(text: 'Flashcards'), Tab(text: 'Favorites')]),
      ),
      body: _p == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_browse(), AcademyFlashcards(onChanged: () => setState(() {})), _favorites()],
            ),
    );
  }
}

/// Spaced-repetition flashcards (Leitner boxes: 1, 2, 4, 8, 16 days).
class AcademyFlashcards extends StatefulWidget {
  final VoidCallback? onChanged;
  const AcademyFlashcards({super.key, this.onChanged});

  @override
  State<AcademyFlashcards> createState() => _AcademyFlashcardsState();
}

class _AcademyFlashcardsState extends State<AcademyFlashcards> {
  final SpeechService _speech = SpeechService();
  List<AcademyWord> _queue = [];
  int _i = 0;
  bool _revealed = false;
  bool _loaded = false;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    _speech.stopSpeaking();
    super.dispose();
  }

  Future<void> _build() async {
    final p = await AcademyProgressStore.load();
    final due = p.dueWords().toSet();
    final byWord = {for (final w in AcademyRepository.words) w.word: w};
    final queue = <AcademyWord>[
      for (final d in due)
        if (byWord[d] != null) byWord[d]!,
    ];
    // Add new words (never reviewed) up to the daily goal.
    for (final w in AcademyRepository.words) {
      if (queue.length >= p.dailyWordGoal) break;
      if (!p.srBox.containsKey(w.word)) queue.add(w);
    }
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _i = 0;
      _revealed = false;
      _loaded = true;
    });
  }

  Future<void> _answer(bool knew) async {
    final w = _queue[_i];
    await AcademyProgressStore.update((p) => p.reviewWord(w.word, knew));
    widget.onChanged?.call();
    setState(() {
      _reviewed++;
      _i++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_queue.isEmpty || _i >= _queue.length) {
      return AppEmptyState(
        icon: Icons.check_circle_outline,
        message: _reviewed > 0
            ? 'Session complete — $_reviewed words reviewed.\nCome back tomorrow for your next review.'
            : 'Nothing due right now. New words appear here every day.',
        ctaLabel: 'Study again',
        onCta: _build,
      );
    }
    final w = _queue[_i];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text('Card ${_i + 1} of ${_queue.length}', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Text(w.word, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.volume_up_outlined), onPressed: () => _speech.speak(w.word)),
              if (_revealed) ...[
                const Divider(),
                Text(w.hindi, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(w.meaning, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('"${w.example}"', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              ] else
                Text('Think of the meaning, then reveal.', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!_revealed)
          PrimaryButton(label: 'Show answer', onPressed: () => setState(() => _revealed = true))
        else
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Not yet', onPressed: () => _answer(false))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: PrimaryButton(label: 'I knew it', onPressed: () => _answer(true))),
            ],
          ),
      ],
    );
  }
}
