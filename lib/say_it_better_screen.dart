import 'package:flutter/material.dart';
import 'say_it_better_service.dart';
import 'say_it_better_result.dart';

class SayItBetterScreen extends StatefulWidget {
  const SayItBetterScreen({super.key});

  @override
  State<SayItBetterScreen> createState() => _SayItBetterScreenState();
}

class _SayItBetterScreenState extends State<SayItBetterScreen> {
  final TextEditingController _controller = TextEditingController();
  final SayItBetterService _service = SayItBetterService();
  SayItBetterResult? _result;
  bool _loading = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await _service.improve(text);
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Say It Better')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type any sentence and see how it could sound more natural, '
              'correct, professional, or casual.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. "I want to discuss about the target."',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Improve This'),
            ),
            const SizedBox(height: 20),
            if (_result != null) Expanded(child: _buildResult(_result!)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(SayItBetterResult r) {
    if (r.isAlreadyGood) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "That already sounds good! ${r.explanation}",
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView(
      children: [
        _versionCard('Original', r.original, Colors.grey),
        if (r.correct != null) _versionCard('Correct', r.correct!, Colors.red),
        if (r.natural != null) _versionCard('Natural', r.natural!, Colors.blue),
        if (r.professional != null)
          _versionCard('Professional', r.professional!, Colors.indigo),
        if (r.casual != null) _versionCard('Casual', r.casual!, Colors.teal),
        const SizedBox(height: 8),
        Text(r.explanation, style: const TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _versionCard(String label, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}
