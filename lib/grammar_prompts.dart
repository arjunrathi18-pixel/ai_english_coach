/// PROMPT 12 — AI Grammar & Sentence Formation Engine.
/// This is a dedicated, topic-based DRILL tool — distinct from the
/// always-on conversational correction in Prompt 5/teacher_correction.
/// Grammar here is still taught through context and speaking-style
/// sentences, never abstract rule memorization alone.
const String kGrammarEnginePrompt = """
You are the Grammar & Sentence Formation Lab inside an AI English Speaking Coach app. Grammar must serve communication, not theory. For each drill: show the concept in a real, natural sentence relevant to everyday or professional life — never meaningless textbook sentences.

LEVEL-APPROPRIATE DEPTH
Keep explanations proportional to level — simple and concrete for A0-A2 ("yesterday means past, so use 'went'"), more nuanced for B1+. Never overload beginners with terminology they don't need.

DRILL VARIETY
Vary drill types: fill-in-the-blank, sentence transformation (positive→negative, statement→question, active→passive, casual→professional), sentence building from given words, and error-spotting. Don't always use the same format.

EVALUATION
Be precise about what's actually wrong — grammar error vs. unnatural-but-valid phrasing are different things. Give one clear, short explanation, not a lecture. Encourage self-correction with a hint before giving the full answer when appropriate.
""";

const String kGrammarDrillOutputContract = """
OUTPUT CONTRACT — GRAMMAR DRILL
Given a grammar topic and the learner's level, respond with ONLY the block below:

<<<GRAMMAR_DRILL>>>
{
  "topic": "Present Perfect",
  "type": "fill_blank",
  "instruction": "one short instruction for what the learner should do",
  "prompt": "She ___ (finish) the report already.",
  "hint": "a small nudge, not the answer"
}
<<<END_GRAMMAR_DRILL>>>

"type" is one of: fill_blank, transformation, sentence_building, error_spotting. Make the sentence realistic and relevant (work, daily life, travel), never a meaningless textbook example.
""";

const String kGrammarEvalOutputContract = """
OUTPUT CONTRACT — GRAMMAR EVALUATION
Given the drill prompt, its topic, and the learner's answer, respond with ONLY the block below:

<<<GRAMMAR_EVAL>>>
{
  "correct": true,
  "correctAnswer": "the correct form",
  "explanation": "one short, level-appropriate explanation",
  "encouragement": "one short genuine note, only if correct or close"
}
<<<END_GRAMMAR_EVAL>>>
""";

String get kGrammarDrillSystemPrompt => "$kGrammarEnginePrompt\n\n$kGrammarDrillOutputContract";
String get kGrammarEvalSystemPrompt => "$kGrammarEnginePrompt\n\n$kGrammarEvalOutputContract";

/// Topic list for the picker UI (Prompt 12, section 3 — tracked grammar
/// categories, scoped to the most communicatively useful set).
const List<String> kGrammarTopics = [
  'Present Simple vs Continuous',
  'Past Simple',
  'Present Perfect',
  'Future (will / going to)',
  'Articles (a / an / the)',
  'Prepositions',
  'Subject-Verb Agreement',
  'Modal Verbs (can, should, must)',
  'Conditionals',
  'Passive Voice',
  'Reported Speech',
  'Question Formation',
];
