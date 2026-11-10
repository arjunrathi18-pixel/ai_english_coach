class MeetingSetup {
  final String counterpartRole;
  final String openingLine;
  final List<String> agendaItems;

  MeetingSetup({
    required this.counterpartRole,
    required this.openingLine,
    required this.agendaItems,
  });

  factory MeetingSetup.fromJson(Map<String, dynamic> json) => MeetingSetup(
        counterpartRole: json['counterpartRole'] as String,
        openingLine: json['openingLine'] as String,
        agendaItems: List<String>.from(json['agendaItems'] as List? ?? []),
      );
}

class ActionItem {
  final String item;
  final String owner;
  final String deadline;
  ActionItem({required this.item, required this.owner, required this.deadline});

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        item: json['item'] as String,
        owner: json['owner'] as String,
        deadline: json['deadline'] as String,
      );
}

class MeetingSummary {
  final List<String> keyPoints;
  final List<String> decisions;
  final List<ActionItem> actionItems;
  final List<String> openQuestions;
  final String communicationFeedback;

  MeetingSummary({
    required this.keyPoints,
    required this.decisions,
    required this.actionItems,
    required this.openQuestions,
    required this.communicationFeedback,
  });

  factory MeetingSummary.fromJson(Map<String, dynamic> json) => MeetingSummary(
        keyPoints: List<String>.from(json['keyPoints'] as List? ?? []),
        decisions: List<String>.from(json['decisions'] as List? ?? []),
        actionItems: (json['actionItems'] as List? ?? [])
            .map((a) => ActionItem.fromJson(a as Map<String, dynamic>))
            .toList(),
        openQuestions: List<String>.from(json['openQuestions'] as List? ?? []),
        communicationFeedback: json['communicationFeedback'] as String? ?? '',
      );
}

class EmailDraft {
  final String subject;
  final String body;
  final String tips;
  EmailDraft({required this.subject, required this.body, required this.tips});

  factory EmailDraft.fromJson(Map<String, dynamic> json) => EmailDraft(
        subject: json['subject'] as String,
        body: json['body'] as String,
        tips: json['tips'] as String? ?? '',
      );
}

class EmailCritique {
  final String strength;
  final String mainIssue;
  final String improvedVersion;
  final String explanation;
  EmailCritique({
    required this.strength,
    required this.mainIssue,
    required this.improvedVersion,
    required this.explanation,
  });

  factory EmailCritique.fromJson(Map<String, dynamic> json) => EmailCritique(
        strength: json['strength'] as String,
        mainIssue: json['mainIssue'] as String,
        improvedVersion: json['improvedVersion'] as String,
        explanation: json['explanation'] as String,
      );
}
