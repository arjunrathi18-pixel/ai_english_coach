import 'package:flutter/material.dart';

import 'chat_message.dart';
import 'chat_bubble.dart';
import 'roleplay_models.dart';
import 'roleplay_service.dart';
import 'roleplay_feedback_screen.dart';
import 'speech_service.dart';
import 'session_settings.dart';
import 'correction_intensity.dart';

class RoleplayScreen extends StatefulWidget {
  final RoleplayScenario scenario;
  const RoleplayScreen({super.key, required this.scenario});

  @override
  State<RoleplayScreen> createState() => _RoleplayScreenState();
}

class _RoleplayScreenState extends State<RoleplayScreen> {
  final List<ChatMessage> _messages = [];
  final RoleplayService _service = RoleplayService();
  final SpeechService _speech = SpeechService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isThinking = false;
  bool _isListening = false;
  bool _isEnding = false;
  String _liveTranscript = '';
  // Reuses the same intensity default as normal chat — a future version
  // could pass the learner's actual chosen SessionSettings through here.
  final String _correctionIntensityKey =
      SessionSettings().correctionIntensity.key;

  @override
  void initState() {
    super.initState();
    _speech.init();
    _messages.add(ChatMessage(
      text: widget.scenario.openingLine,
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
    if (text.trim().isEmpty || _isThinking) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _isThinking = true;
      _liveTranscript = '';
    });
    _controller.clear();
    _scrollToBottom();

    final reply = await _service.getNextTurn(
      scenario: widget.scenario,
      history: _messages,
      correctionIntensityKey: _correctionIntensityKey,
    );

    setState(() {
      _messages.add(ChatMessage(text: reply, sender: SenderType.ai));
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

  Future<void> _endRoleplay() async {
    if (_messages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play out a bit more of the scene first.')),
      );
      return;
    }
    setState(() => _isEnding = true);
    final feedback = await _service.getFeedback(
      scenario: widget.scenario,
      history: _messages,
    );
    setState(() => _isEnding = false);

    if (feedback == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate feedback — try again.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RoleplayFeedbackScreen(feedback: feedback)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    return Scaffold(
      appBar: AppBar(
        title: Text(scenario.title),
        actions: [
          IconButton(
            tooltip: 'End roleplay & get feedback',
            onPressed: _isEnding ? null : _endRoleplay,
            icon: _isEnding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You: ${scenario.learnerRole}  •  Them: ${scenario.aiRole}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(scenario.situationBriefing,
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('…', style: TextStyle(color: Colors.black45)),
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
                style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
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
                        hintText: 'Say your line…',
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
