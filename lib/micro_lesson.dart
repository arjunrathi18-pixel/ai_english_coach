/// A short, focused lesson auto-generated from a recurring mistake
/// pattern (Prompt 5, section 20) — rule + examples + one practice item,
/// deliberately kept brief.
class MicroLesson {
  final String topic;
  final String rule;
  final List<String> examples;
  final String practicePrompt; // e.g. "She ___ the work." or a speaking task
  final String practiceAnswer; // what a correct response looks like

  MicroLesson({
    required this.topic,
    required this.rule,
    required this.examples,
    required this.practicePrompt,
    required this.practiceAnswer,
  });

  factory MicroLesson.fromJson(Map<String, dynamic> json) => MicroLesson(
        topic: json['topic'] as String,
        rule: json['rule'] as String,
        examples: List<String>.from(json['examples'] as List),
        practicePrompt: json['practicePrompt'] as String,
        practiceAnswer: json['practiceAnswer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'rule': rule,
        'examples': examples,
        'practicePrompt': practicePrompt,
        'practiceAnswer': practiceAnswer,
      };
}
