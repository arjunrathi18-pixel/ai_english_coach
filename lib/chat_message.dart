enum SenderType { user, ai }

class ChatMessage {
  final String text;
  final SenderType sender;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'sender': sender.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        sender: json['sender'] == 'user' ? SenderType.user : SenderType.ai,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
