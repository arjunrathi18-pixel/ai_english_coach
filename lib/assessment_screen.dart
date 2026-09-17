import 'package:flutter/material.dart';

import 'assessment_result_screen.dart';
import 'assessment_service.dart';
import 'chat_message.dart';
import 'chat_bubble.dart';
import 'learner_profile.dart';
import 'profile_store.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final AssessmentService _service = AssessmentService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isThinking = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    // Fixed opening line — keeps the very first turn instant instead of
    // waiting on a network call, and gives the assessment a warm start.
    _messages.add(ChatMessage(
      text: "Let's get to know your English a little — no pressure, this "
          "isn't a school test. To start, what's your name, and what do "
          "you do?",
      sender: SenderType.ai,
    ));
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
    if (text.trim().isEmpty || _isThinking || _isDone) return;

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _isThinking = true;
    });
    _controller.clear();
    _scrollToBottom();

    final rawReply = await _service.getNextTurn(_messages);
    final profile = _service.tryParseResult(rawReply);
    final visibleText = _service.stripResultBlock(rawReply);

    setState(() {
      _messages.add(ChatMessage(text: visibleText, sender: SenderType.ai));
      _isThinking = false;
    });
    _scrollToBottom();

    if (profile != null) {
      setState(() => _isDone = true);
      await ProfileStore.save(profile);
      await Future.delayed(const Duration(milliseconds: 600));
      _goToResults(profile);
    }
  }

  void _goToResults(LearnerProfile profile) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('English Level Assessment')),
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
                    child: Text('Thinking…',
                        style: TextStyle(color: Colors.black45)),
                  );
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (!_isDone) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type your answer…',
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
            IconButton(
              onPressed: () => _send(_controller.text),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
