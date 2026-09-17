import 'package:flutter/material.dart';
import 'curriculum.dart';
import 'curriculum_store.dart';
import 'micro_lesson_screen.dart';

class MyMistakesScreen extends StatefulWidget {
  const MyMistakesScreen({super.key});

  @override
  State<MyMistakesScreen> createState() => _MyMistakesScreenState();
}

class _MyMistakesScreenState extends State<MyMistakesScreen> {
  List<RecurringMistake> _mistakes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mistakes = await CurriculumStore.loadMistakes();
    // Most frequent / most recent first — that's what's most worth revising.
    mistakes.sort((a, b) => b.timesObserved.compareTo(a.timesObserved));
    setState(() {
      _mistakes = mistakes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Mistakes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mistakes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "No recurring mistakes tracked yet — keep practicing "
                      "and this will fill in automatically.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mistakes.length,
                  itemBuilder: (context, index) {
                    final m = _mistakes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(m.pattern),
                        subtitle: Text('Seen ${m.timesObserved} time(s)'),
                        trailing: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MicroLessonScreen(
                                  mistakePattern: m.pattern,
                                ),
                              ),
                            );
                          },
                          child: const Text('Learn This'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
