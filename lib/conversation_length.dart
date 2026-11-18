/// How long the learner wants this conversation to run (Prompt 4,
/// section 11). This shapes pacing, not content difficulty.
enum ConversationLength {
  quickChat, // 1-3 min
  shortPractice, // 5 min
  normal, // 10-15 min
  deep, // 20-30 min
  long, // 30+ min
}

extension ConversationLengthLabel on ConversationLength {
  String get label {
    switch (this) {
      case ConversationLength.quickChat:
        return 'Quick Chat';
      case ConversationLength.shortPractice:
        return 'Short Practice';
      case ConversationLength.normal:
        return 'Normal';
      case ConversationLength.deep:
        return 'Deep Conversation';
      case ConversationLength.long:
        return 'Long Conversation';
    }
  }

  String get description {
    switch (this) {
      case ConversationLength.quickChat:
        return '1-3 minutes';
      case ConversationLength.shortPractice:
        return '5 minutes';
      case ConversationLength.normal:
        return '10-15 minutes';
      case ConversationLength.deep:
        return '20-30 minutes';
      case ConversationLength.long:
        return '30+ minutes';
    }
  }

  String get key => toString().split('.').last;

  static ConversationLength fromKey(String key) {
    return ConversationLength.values.firstWhere(
      (l) => l.key == key,
      orElse: () => ConversationLength.normal,
    );
  }
}
