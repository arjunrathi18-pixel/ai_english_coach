/// Generates a short, targeted lesson from one recurring mistake pattern
/// (Prompt 5, section 20), and evaluates the learner's one practice
/// attempt afterward (sections 18-19).
const String kMicroLessonPrompt = """
You generate a short, focused micro-lesson for one recurring English mistake pattern inside an AI English Speaking Coach app. Keep it brief — this is a quick, targeted fix, not a full grammar chapter.

Include: the topic name, one clear plain-language rule (no unnecessary terminology for lower levels), 2-3 short example sentences showing correct use, and exactly one practice item — either a fill-in-the-blank sentence or a short speaking prompt — along with what a correct response looks like.
""";

const String kMicroLessonOutputContract = """
OUTPUT CONTRACT
Respond with ONLY the block below — no other text:

<<<MICRO_LESSON>>>
{
  "topic": "Third-person singular present tense",
  "rule": "one clear sentence stating the rule",
  "examples": ["example 1", "example 2", "example 3"],
  "practicePrompt": "She ___ to work every day.",
  "practiceAnswer": "goes"
}
<<<END_MICRO_LESSON>>>
""";

String get kMicroLessonSystemPrompt =>
    "$kMicroLessonPrompt\n\n$kMicroLessonOutputContract";

/// Used once the learner submits their practice attempt — a lightweight,
/// single-turn check rather than a full conversation.
const String kMicroLessonEvaluationPrompt = """
You are checking one short practice answer against a specific English rule inside an AI English Speaking Coach app. Be encouraging and brief. If it's correct, confirm it plainly. If not, show the correct form and explain the fix in one short sentence — never a long lecture.
""";

const String kMicroLessonEvaluationOutputContract = """
OUTPUT CONTRACT
Respond with ONLY the block below — no other text:

<<<EVALUATION>>>
{
  "isCorrect": true,
  "feedback": "one short encouraging sentence, or the correction if wrong"
}
<<<END_EVALUATION>>>
""";

String get kMicroLessonEvaluationSystemPrompt =>
    "$kMicroLessonEvaluationPrompt\n\n$kMicroLessonEvaluationOutputContract";
