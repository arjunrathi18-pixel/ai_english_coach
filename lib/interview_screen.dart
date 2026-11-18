import 'package:flutter/material.dart';
import 'design_tokens.dart';

import 'chat_message.dart';
import 'chat_bubble.dart';
import 'interview_models.dart';
import 'interview_service.dart';
import 'interview_report_screen.dart';
import 'speech_service.dart';
import 'session_settings.dart';
import 'correction_intensity.dart';

class InterviewScreen extends StatefulWidget {
  final JobProfile profile;
  final InterviewSetup setup;
  final InterviewType type;
  final InterviewMode mode;

  const InterviewScreen({
    super.key,
    required this.profile,
    required this.setup,
    required this.type,
    required this.mode,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final List<ChatMessage> _messages = [];
  final InterviewService _service = InterviewService();
  final SpeechService _speech = SpeechService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isThinking = false;
  bool _isListening = false;
  bool _isEnding = false;
  bool _isImproving = false;
  String _liveTranscript = '';
  final String _correctionIntensityKey =
      SessionSettings().correctionIntensity.key;

  String? _lastQuestion;
  String? _lastAnswer;

  @override
  void initState() {
    super.initState();
    _speech.init();
    _messages.add(ChatMessage(text: widget.setup.openingLine, sender: SenderType.ai));
    _lastQuestion = widget.setup.openingLine;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isThinking) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _lastAnswer = text.trim();
      _isThinking = true;
      _liveTranscript = '';
    });
    _controller.clear();
    _scrollToBottom();

    final reply = await _service.getNextTurn(
      profile: widget.profile,
      setup: widget.setup,
      type: widget.type,
      mode: widget.mode,
      history: _messages,
      correctionIntensityKey: _correctionIntensityKey,
    );

    setState(() {
      _messages.add(ChatMessage(text: reply, sender: SenderType.ai));
      _lastQuestion = reply;
      _isThinking = false;
    });
    _scrollToBottom();
    await _speech.speak(reply);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stopListening();
      setState(() => _isListening = false);
      if (_liveTranscript.trim().isNotEmpty) _send(_liveTranscript);
      return;
    }
    if (!_speech.isAvailable) {
      final ok = await _speech.init();
      if (!ok) return;
    }
    setState(() => _isListening = true);
    await _speech.startListening(
      onResult: (t) => setState(() => _liveTranscript = t),
    );
  }

  Future<void> _improveLastAnswer() async {
    if (_lastAnswer == null || _lastQuestion == null) return;
    setState(() => _isImproving = true);
    final improvement = await _service.improveAnswer(
      question: _lastQuestion!,
      answer: _lastAnswer!,
    );
    setState(() => _isImproving = false);

    if (improvement == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Improve This Answer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _levelCard('Simple', improvement.simple, Colors.grey),
            _levelCard('Natural', improvement.natural, AppColors.accentPrimary),
            _levelCard('Strong Professional', improvement.strongProfessional, AppColors.accentPrimary),
            const SizedBox(height: 8),
            Text(improvement.why, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(String label, String text, Color color) {
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
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _endInterview() async {
    if (_messages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer a few more questions before ending.')),
      );
      return;
    }
    setState(() => _isEnding = true);
    final report = await _service.getReport(history: _messages, profile: widget.profile);
    setState(() => _isEnding = false);

    if (report == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate the report — try again.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => InterviewReportScreen(report: report)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setup.interviewerRole),
        actions: [
          IconButton(
            tooltip: 'End interview & get report',
            onPressed: _isEnding ? null : _endInterview,
            icon: _isEnding
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.assessment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('…', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _liveTranscript.isEmpty ? 'Listening…' : _liveTranscript,
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          if (_lastAnswer != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isImproving ? null : _improveLastAnswer,
                icon: _isImproving
                    ? const SizedBox(
                        width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Improve my last answer'),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Your answer…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _toggleListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  ),
                  IconButton(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
