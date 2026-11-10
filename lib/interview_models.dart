/// What the learner tells the app about the role they're preparing for
/// (Prompt 10, sections 5-6). Resume/JD text is optional free text the
/// learner pastes in — never invented by the AI.
class JobProfile {
  final String jobTitle;
  final String company; // optional, may be empty
  final String industry;
  final String experienceLevel; // e.g. "3 years", "fresher", "senior"
  final String keyResponsibilities;
  final String resumeText; // optional, may be empty
  final String jobDescriptionText; // optional, may be empty

  JobProfile({
    required this.jobTitle,
    this.company = '',
    required this.industry,
    required this.experienceLevel,
    this.keyResponsibilities = '',
    this.resumeText = '',
    this.jobDescriptionText = '',
  });

  String toPromptSummary() => """
Job title: $jobTitle
Company: ${company.isEmpty ? 'not specified' : company}
Industry: $industry
Experience level: $experienceLevel
Key responsibilities: ${keyResponsibilities.isEmpty ? 'not specified' : keyResponsibilities}
Resume text: ${resumeText.isEmpty ? 'not provided' : resumeText}
Job description text: ${jobDescriptionText.isEmpty ? 'not provided' : jobDescriptionText}
""";
}

/// Interview type (Prompt 10, section 2).
enum InterviewType {
  general,
  hr,
  functional,
  managerial,
  seniorManagement,
  sales,
}

extension InterviewTypeLabel on InterviewType {
  String get label {
    switch (this) {
      case InterviewType.general:
        return 'General';
      case InterviewType.hr:
        return 'HR / Behavioral';
      case InterviewType.functional:
        return 'Functional / Job-specific';
      case InterviewType.managerial:
        return 'Managerial';
      case InterviewType.seniorManagement:
        return 'Senior Management';
      case InterviewType.sales:
        return 'Sales';
    }
  }
}

/// Interview mode (Prompt 10, section 4) — simplified to the modes this
/// app actually implements distinctly.
enum InterviewMode { practice, mock, strict, friendly, rapidFire }

extension InterviewModeLabel on InterviewMode {
  String get label {
    switch (this) {
      case InterviewMode.practice:
        return 'Practice (question by question)';
      case InterviewMode.mock:
        return 'Full Mock Interview';
      case InterviewMode.strict:
        return 'Strict / Realistic';
      case InterviewMode.friendly:
        return 'Friendly';
      case InterviewMode.rapidFire:
        return 'Rapid Fire';
    }
  }
}

class InterviewSetup {
  final String interviewerRole;
  final String openingLine;
  final List<String> focusAreas;

  InterviewSetup({
    required this.interviewerRole,
    required this.openingLine,
    required this.focusAreas,
  });

  factory InterviewSetup.fromJson(Map<String, dynamic> json) =>
      InterviewSetup(
        interviewerRole: json['interviewerRole'] as String,
        openingLine: json['openingLine'] as String,
        focusAreas: List<String>.from(json['focusAreas'] as List? ?? []),
      );
}

class AnswerImprovement {
  final String simple;
  final String natural;
  final String strongProfessional;
  final String why;

  AnswerImprovement({
    required this.simple,
    required this.natural,
    required this.strongProfessional,
    required this.why,
  });

  factory AnswerImprovement.fromJson(Map<String, dynamic> json) =>
      AnswerImprovement(
        simple: json['simple'] as String,
        natural: json['natural'] as String,
        strongProfessional: json['strongProfessional'] as String,
        why: json['why'] as String,
      );
}

class QuestionAnswerPair {
  final String question;
  final String answer;
  QuestionAnswerPair({required this.question, required this.answer});

  factory QuestionAnswerPair.fromJson(Map<String, dynamic> json) =>
      QuestionAnswerPair(
        question: json['question'] as String,
        answer: (json['answer'] ?? json['originalAnswer']) as String,
      );
}

class InterviewReport {
  final String overallPerformance;
  final List<String> strongAreas;
  final List<String> areasToImprove;
  final Map<String, String> englishNotes;
  final Map<String, String> interviewSkillNotes;
  final String mostImportantImprovement;
  final QuestionAnswerPair bestAnswer;
  final String improvedVersion;
  final QuestionAnswerPair answerNeedingImprovement;
  final List<String> recommendedPractice;
  final List<String> recurringIssues;

  InterviewReport({
    required this.overallPerformance,
    required this.strongAreas,
    required this.areasToImprove,
    required this.englishNotes,
    required this.interviewSkillNotes,
    required this.mostImportantImprovement,
    required this.bestAnswer,
    required this.improvedVersion,
    required this.answerNeedingImprovement,
    required this.recommendedPractice,
    required this.recurringIssues,
  });

  factory InterviewReport.fromJson(Map<String, dynamic> json) {
    final needsImprovement =
        json['answerNeedingImprovement'] as Map<String, dynamic>;
    return InterviewReport(
      overallPerformance: json['overallPerformance'] as String,
      strongAreas: List<String>.from(json['strongAreas'] as List? ?? []),
      areasToImprove: List<String>.from(json['areasToImprove'] as List? ?? []),
      englishNotes: Map<String, String>.from(json['englishNotes'] as Map? ?? {}),
      interviewSkillNotes:
          Map<String, String>.from(json['interviewSkillNotes'] as Map? ?? {}),
      mostImportantImprovement: json['mostImportantImprovement'] as String,
      bestAnswer:
          QuestionAnswerPair.fromJson(json['bestAnswer'] as Map<String, dynamic>),
      improvedVersion: needsImprovement['improvedVersion'] as String,
      answerNeedingImprovement: QuestionAnswerPair.fromJson(needsImprovement),
      recommendedPractice:
          List<String>.from(json['recommendedPractice'] as List? ?? []),
      recurringIssues: List<String>.from(json['recurringIssues'] as List? ?? []),
    );
  }
}
