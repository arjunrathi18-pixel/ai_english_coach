import 'package:flutter/material.dart';
import 'micro_lesson.dart';
import 'micro_lesson_service.dart';

class MicroLessonScreen extends StatefulWidget {
  final String mistakePattern;
  const MicroLessonScreen({super.key, required this.mistakePattern});

  @override
  State<MicroLessonScreen> createState() => _MicroLessonScreenState();
}

class _MicroLessonScreenState extends State<MicroLessonScreen> {
  final MicroLessonService _service = MicroLessonService();
  final TextEditingController _answerController = TextEditingController();

  MicroLesson? _lesson;
  bool _loading = true;
  bool _checking = false;
  String? _feedback;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lesson = await _service.generate(widget.mistakePattern);
    setState(() {
      _lesson = lesson;
      _loading = false;
    });
  }

  Future<void> _checkAnswer() async {
    if (_lesson == null || _answerController.text.trim().isEmpty) return;
    setState(() => _checking = true);
    final result = await _service.evaluate(
      lesson: _lesson!,
      learnerAnswer: _answerController.text.trim(),
    );
    setState(() {
      _checking = false;
      if (result != null) {
        _isCorrect = result.$1;
        _feedback = result.$2;
      } else {
        _feedback = 'Could not check that right now — try again.';
      }
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Lesson')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lesson == null
              ? const Center(child: Text('Could not generate this lesson.'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      Text(_lesson!.topic,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(_lesson!.rule),
                      const SizedBox(height: 16),
                      const Text('Examples',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ..._lesson!.examples.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• $e'),
                          )),
                      const SizedBox(height: 24),
                      const Text('Your turn',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_lesson!.practicePrompt),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _answerController,
                        decoration: const InputDecoration(
                          hintText: 'Type your answer…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _checking ? null : _checkAnswer,
                        child: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Check'),
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_isCorrect == true
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_feedback!),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
