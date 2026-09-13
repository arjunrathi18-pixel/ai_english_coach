import 'package:flutter/material.dart';

import 'chat_message.dart';
import 'session_settings.dart';
import 'ai_tutor_service.dart';
import 'speech_service.dart';
import 'chat_bubble.dart';
import 'mode_selector.dart';

class ChatScreen extends StatefulWidget {
  /// Optional level from a completed assessment (e.g. "B1"). When provided,
  /// the session starts pre-tuned to that level instead of "unknown".
  final String? initialEstimatedLevel;

  const ChatScreen({super.key, this.initialEstimatedLevel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final AiTutorService _aiService = AiTutorService();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SessionSettings _settings = SessionSettings();
  bool _isThinking = false;
  bool _isListening = false;
  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialEstimatedLevel != null) {
      _settings = _settings.copyWith(
        estimatedLevel: widget.initialEstimatedLevel,
      );
    }
    _speechService.init();
    _messages.add(ChatMessage(
      text: "Hey! I'm your English speaking coach. We can just chat — "
          "tell me about your day, or ask me to switch to Tutor or Coach mode "
          "whenever you want. What's on your mind?",
      sender: SenderType.ai,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _isThinking = true;
      _liveTranscript = '';
    });
    _textController.clear();
    _scrollToBottom();

    final reply = await _aiService.getNextReply(
      history: _messages,
      settings: _settings,
    );

    setState(() {
      _messages.add(ChatMessage(text: reply, sender: SenderType.ai));
      _isThinking = false;
    });
    _scrollToBottom();
    await _speechService.speak(reply);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      if (_liveTranscript.trim().isNotEmpty) {
        _sendMessage(_liveTranscript);
      }
      return;
    }

    if (!_speechService.isAvailable) {
      final ok = await _speechService.init();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is needed for voice practice.'),
          ),
        );
        return;
      }
    }

    setState(() => _isListening = true);
    await _speechService.startListening(
      onResult: (text) => setState(() => _liveTranscript = text),
    );
  }

  void _onModeChanged(String mode) {
    setState(() => _settings = _settings.copyWith(mode: mode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speak with your Coach')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ModeSelector(selectedMode: _settings.mode, onChanged: _onModeChanged),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Coach is thinking…',
                        style: TextStyle(color: Colors.black45)),
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
          _buildInputBar(),
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
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type or tap the mic to speak…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _toggleListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
            ),
            IconButton(
              onPressed: () => _sendMessage(_textController.text),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
