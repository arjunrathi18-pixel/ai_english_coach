import 'package:flutter/material.dart';
import 'presentation_debate_service.dart';
import 'presentation_debate_models.dart';
import 'chat_message.dart';
import 'chat_bubble.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

const List<String> kDebateTopics = [
  'Should companies allow fully remote work?',
  'Is social media more harmful than helpful?',
  'Should students learn financial literacy in school?',
  'Is artificial intelligence a net positive for jobs?',
  'Should salary expectations be discussed early in interviews?',
];

class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  final PresentationDebateService _service = PresentationDebateService();
  final _customTopicController = TextEditingController();
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _topic;
  String _position = 'for';
  final List<ChatMessage> _messages = [];
  bool _started = false;
  bool _isThinking = false;
  bool _isEnding = false;
  DebateFeedback? _feedback;

  Future<void> _start(String topic) async {
    setState(() {
      _topic = topic;
      _started = true;
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _topic == null) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), sender: SenderType.user));
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();
    final reply = await _service.getDebateOpponentTurn(
      topic: _topic!,
      learnerPosition: _position,
      history: _messages,
    );
    setState(() {
      _messages.add(ChatMessage(text: reply, sender: SenderType.ai));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _endDebate() async {
    if (_messages.length < 2) return;
    setState(() => _isEnding = true);
    final feedback = await _service.getDebateFeedback(_messages);
    setState(() {
      _isEnding = false;
      _feedback = feedback;
    });
    if (feedback != null) await GamificationService.recordCompletion(xp: 25);
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_feedback != null) return _buildFeedback();
    if (!_started) return _buildSetup();
    return _buildDebate();
  }

  Widget _buildSetup() {
    return Scaffold(
      appBar: AppBar(title: const Text('Debate Practice')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Text('Your position', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['for', 'against'].map((p) => ChoiceChip(
                  label: Text(p),
                  selected: _position == p,
                  onSelected: (_) => setState(() => _position = p),
                )).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _customTopicController,
            decoration: const InputDecoration(labelText: 'Custom topic (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_customTopicController.text.trim().isNotEmpty)
            PrimaryButton(label: 'Start Debate', onPressed: () => _start(_customTopicController.text.trim())),
          const SizedBox(height: AppSpacing.xl),
          const Text('Or pick a topic', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...kDebateTopics.map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(title: Text(t), onTap: () => _start(t)),
              )),
        ],
      ),
    );
  }

  Widget _buildDebate() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_topic!, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'End debate & get feedback',
            onPressed: _isEnding ? null : _endDebate,
            icon: _isEnding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.accentPrimary.withOpacity(0.06),
            child: Text('You argue: $_position. State your opening argument.', style: Theme.of(context).textTheme.bodySmall),
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
                        hintText: 'Your argument…',
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

  Widget _buildFeedback() {
    final f = _feedback!;
    return Scaffold(
      appBar: AppBar(title: const Text('Debate Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _fbCard('Argument Clarity', f.argumentClarity, AppColors.accentPrimary),
          const SizedBox(height: 8),
          _fbCard('Reasoning', f.reasoning, AppColors.accentSecondary),
          const SizedBox(height: 8),
          _fbCard('Counterargument Handling', f.counterargumentHandling, AppColors.success),
          const SizedBox(height: 8),
          _fbCard('Main Improvement', f.mainImprovement, AppColors.warning),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to Home')),
        ],
      ),
    );
  }

  Widget _fbCard(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
