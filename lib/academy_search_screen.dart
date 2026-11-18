import 'package:flutter/material.dart';
import 'academy_repository.dart';
import 'academy_vocab_screen.dart';
import 'academy_grammar_screen.dart';
import 'academy_interview_screen.dart';
import 'academy_reading_screen.dart';
import 'academy_sentences_screen.dart';
import 'design_tokens.dart';

/// One search box across words, sentences, grammar lessons, interview
/// questions and reading passages — fully offline.
class AcademySearchScreen extends StatefulWidget {
  const AcademySearchScreen({super.key});

  @override
  State<AcademySearchScreen> createState() => _AcademySearchScreenState();
}

class _AcademySearchScreenState extends State<AcademySearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = AcademyRepository.searchAll(_controller.text);
    final query = _controller.text.trim();

    Widget header(String t, int n) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 4),
          child: Text('$t ($n)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Search Academy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search words, sentences, lessons… (English or Hindi)', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => setState(() {}),
          ),
          if (query.isNotEmpty && r.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Nothing found in the offline content for "$query".', style: theme.textTheme.bodyMedium),
            ),
          if (r.lemmaNote != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.lemmaNote!, style: theme.textTheme.bodySmall)),
          if (r.words.isNotEmpty) ...[
            header('Words', r.words.length),
            ...r.words.take(8).map((w) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(w.word),
                  subtitle: Text('${w.hindi} · ${w.level}'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AcademyVocabScreen(initialQuery: w.word))),
                )),
          ],
          if (r.lessons.isNotEmpty) ...[
            header('Grammar lessons', r.lessons.length),
            ...r.lessons.map((l) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.title),
                  subtitle: Text(l.level),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AcademyLessonScreen(lesson: l))),
                )),
          ],
          if (r.sentences.isNotEmpty) ...[
            header('Sentences', r.sentences.length),
            ...r.sentences.take(6).map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.en),
                  subtitle: Text(s.hi),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AcademySentencesScreen())),
                )),
          ],
          if (r.interviews.isNotEmpty) ...[
            header('Interview questions', r.interviews.length),
            ...r.interviews.take(6).map((i) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(i.question),
                  subtitle: Text(i.category),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AcademyInterviewScreen())),
                )),
          ],
          if (r.passages.isNotEmpty) ...[
            header('Reading', r.passages.length),
            ...r.passages.map((p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.title),
                  subtitle: Text(p.level),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AcademyReadingScreen())),
                )),
          ],
        ],
      ),
    );
  }
}
