import 'package:flutter/material.dart';

import 'business_models.dart';
import 'business_service.dart';
import 'chat_message.dart';
import 'chat_bubble.dart';
import 'speech_service.dart';
import 'meeting_summary_screen.dart';
import 'profile_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _topicController = TextEditingController();
  final _roleController = TextEditingController();
  final BusinessService _service = BusinessService();
  final SpeechService _speech = SpeechService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  MeetingSetup? _setup;
  final List<ChatMessage> _messages = [];
  bool _generating = false;
  bool _isThinking = false;
  bool _isEnding = false;
  String _level = 'unknown';

  @override
  void initState() {
    super.initState();
    _speech.init();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  Future<void> _startMeeting() async {
    if (_topicController.text.trim().isEmpty || _roleController.text.trim().isEmpty) return;
    setState(() => _generating = true);
    final setup = await _service.setupMeeting(
      topic: _topicController.text.trim(),
      learnerRole: _roleController.text.trim(),
      level: _level,
    );
    setState(() {
      _generating = false;
      _setup = setup;
      if (setup != null) {
        _messages.add(ChatMessage(text: setup.openingLine, sender: SenderType.ai));
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _setup == null) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();
    final reply = await _service.getMeetingTurn(
      setup: _setup!,
      topic: _topicController.text.trim(),
      history: _messages,
    );
    setState(() {
      _messages.add(ChatMessage(text: reply, sender: SenderType.ai));
      _isThinking = false;
    });
    _scrollToBottom();
    await _speech.speak(reply);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _endMeeting() async {
    if (_messages.length < 3) return;
    setState(() => _isEnding = true);
    final summary = await _service.getMeetingSummary(_messages);
    setState(() => _isEnding = false);
    if (summary == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MeetingSummaryScreen(summary: summary)),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _roleController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_setup == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Simulator')),
        body: _generating
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting topic',
                        hintText: 'e.g. "Q3 project delay"',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Your role in this meeting',
                        hintText: 'e.g. "Team lead giving a status update"',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(label: 'Start Meeting', onPressed: _startMeeting),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_setup!.counterpartRole),
        actions: [
          IconButton(
            tooltip: 'End meeting & get summary',
            onPressed: _isEnding ? null : _endMeeting,
            icon: _isEnding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.summarize_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.accentPrimary.withOpacity(0.06),
            child: Text('Agenda: ${_setup!.agendaItems.join(' • ')}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const ThinkingIndicator();
                return ChatBubble(message: _messages[i]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Your response…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => _send(_inputController.text), icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
