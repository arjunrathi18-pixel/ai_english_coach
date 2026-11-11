/// Built-in practice content. Used when the AI is unavailable (no API key,
/// no internet) so screens are never empty. Plain data only (no model
/// imports) so services can convert it as they need.

// ───────────────────────── GRAMMAR DRILLS ─────────────────────────
// keys match kGrammarTopics exactly.
const Map<String, List<Map<String, Object>>> kLocalGrammarDrills = {
  'Present Simple vs Continuous': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'I usually ___ (start) work at 9 AM.', 'hint': 'Usually = a habit.', 'answers': ['start'], 'why': '"Usually" shows a habit, so use the present simple: start.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'Right now, she ___ (talk) to a client.', 'hint': 'It is happening at this moment.', 'answers': ['is talking', "'s talking"], 'why': '"Right now" means the action is in progress: present continuous.'},
    {'type': 'error_spotting', 'instruction': 'Rewrite the sentence correctly.', 'prompt': 'He is go to office every day.', 'hint': 'Every day = habit.', 'answers': ['he goes to the office every day', 'he goes to office every day'], 'why': 'A daily habit uses the present simple: he goes.'},
    {'type': 'transformation', 'instruction': 'Make it negative.', 'prompt': 'We work on Sundays.', 'hint': 'Use do + not.', 'answers': ['we do not work on sundays', "we don't work on sundays"], 'why': 'Present simple negative: do not / don\'t + base verb.'},
  ],
  'Past Simple': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'Yesterday I ___ (go) to the market.', 'hint': 'Irregular verb.', 'answers': ['went'], 'why': '"Yesterday" is finished past time, so use the past simple: went.'},
    {'type': 'transformation', 'instruction': 'Make it negative.', 'prompt': 'She called me yesterday.', 'hint': 'did + not + base verb.', 'answers': ['she did not call me yesterday', "she didn't call me yesterday"], 'why': 'Past simple negative: did not + base verb (call).'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'Last week we ___ (launch) the new product.', 'hint': 'Regular verb.', 'answers': ['launched'], 'why': 'Finished action last week: launched.'},
    {'type': 'transformation', 'instruction': 'Make it a question.', 'prompt': 'You met the manager.', 'hint': 'Start with Did.', 'answers': ['did you meet the manager'], 'why': 'Past simple question: Did + subject + base verb.'},
  ],
  'Present Perfect': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'I ___ (finish) the report already.', 'hint': 'have/has + past participle.', 'answers': ['have finished', "'ve finished"], 'why': '"Already" connects the past action to now: present perfect.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'She ___ (work) here since 2020.', 'hint': 'Since = from then until now.', 'answers': ['has worked', 'has been working', "'s worked", "'s been working"], 'why': '"Since 2020" continues until now: present perfect.'},
    {'type': 'error_spotting', 'instruction': 'Rewrite the sentence correctly.', 'prompt': 'I have went to Delhi twice.', 'hint': 'Check the past participle of go.', 'answers': ['i have gone to delhi twice', "i've gone to delhi twice"], 'why': 'After have, use the past participle: gone (not went).'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'Have you ever ___ (work) with a difficult client?', 'hint': 'Past participle.', 'answers': ['worked'], 'why': 'Have you ever + past participle: worked.'},
  ],
  'Future (will / going to)': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'Look at those clouds. It ___ (rain).', 'hint': 'You can see evidence now.', 'answers': ['is going to rain', "'s going to rain"], 'why': 'A prediction based on what you see now uses going to.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'The phone is ringing. I ___ (answer) it.', 'hint': 'A decision made at this moment.', 'answers': ['will answer', "'ll answer"], 'why': 'A sudden decision uses will.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'I ___ (meet) the client tomorrow at 10. It is already arranged.', 'hint': 'A fixed arrangement.', 'answers': ['am meeting', "'m meeting"], 'why': 'A fixed arrangement uses the present continuous for the future.'},
    {'type': 'transformation', 'instruction': 'Rewrite as a promise using will.', 'prompt': 'I help you with the report.', 'hint': 'I will / I\'ll.', 'answers': ['i will help you with the report', "i'll help you with the report"], 'why': 'Promises use will + base verb.'},
  ],
  'Articles (a / an / the)': [
    {'type': 'fill_blank', 'instruction': 'Write a, an or the.', 'prompt': 'She works for ___ company in Pune.', 'hint': 'Company starts with a consonant sound.', 'answers': ['a'], 'why': 'One of many companies, consonant sound: a.'},
    {'type': 'fill_blank', 'instruction': 'Write a, an or the.', 'prompt': 'He is ___ honest employee.', 'hint': 'Listen to the first sound of honest.', 'answers': ['an'], 'why': '"Honest" starts with a vowel sound (the h is silent): an.'},
    {'type': 'fill_blank', 'instruction': 'Write a, an or the.', 'prompt': 'I went to ___ office early today. (the office we both know)', 'hint': 'A specific place both people know.', 'answers': ['the'], 'why': 'A specific, known place uses the.'},
    {'type': 'fill_blank', 'instruction': 'Write a, an or the.', 'prompt': '___ sun rises in the east.', 'hint': 'There is only one.', 'answers': ['the'], 'why': 'Unique things (the sun, the moon) use the.'},
  ],
  'Prepositions': [
    {'type': 'fill_blank', 'instruction': 'Fill in the preposition.', 'prompt': 'The meeting is ___ 3 PM.', 'hint': 'Exact time.', 'answers': ['at'], 'why': 'Exact clock times use at.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the preposition.', 'prompt': "I'm interested ___ this role.", 'hint': 'Fixed pattern.', 'answers': ['in'], 'why': 'interested in is a fixed pattern.'},
    {'type': 'error_spotting', 'instruction': 'Rewrite the sentence correctly.', 'prompt': 'We will discuss about the plan.', 'hint': 'Discuss does not need a preposition.', 'answers': ['we will discuss the plan', "we'll discuss the plan"], 'why': '"Discuss" is followed directly by the object: discuss the plan.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the preposition.', 'prompt': 'She depends ___ her manager for guidance.', 'hint': 'Fixed pattern.', 'answers': ['on'], 'why': 'depend on is the correct pattern.'},
  ],
  'Subject-Verb Agreement': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'He ___ (work) in sales.', 'hint': 'He / she / it adds -s.', 'answers': ['works'], 'why': 'Third person singular in present simple: works.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'My manager ___ (like) clear updates.', 'hint': 'One person.', 'answers': ['likes'], 'why': 'Singular subject: likes.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'The team ___ (have) a meeting at 5.', 'hint': 'Team is treated as one group.', 'answers': ['has'], 'why': 'In this usage, team is one unit: has.'},
    {'type': 'error_spotting', 'instruction': 'Rewrite the sentence correctly.', 'prompt': "She don't know the answer.", 'hint': 'Check do / does.', 'answers': ["she doesn't know the answer", 'she does not know the answer'], 'why': 'With she, use does not / doesn\'t.'},
  ],
  'Modal Verbs (can, should, must)': [
    {'type': 'fill_blank', 'instruction': 'Fill in the modal verb.', 'prompt': '___ you send me the report, please? (polite request)', 'hint': 'Polite = more careful than "can".', 'answers': ['could', 'would', 'can'], 'why': '"Could you...?" is a polite request.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the modal verb.', 'prompt': 'You ___ check the numbers before the meeting. (advice)', 'hint': 'Giving advice.', 'answers': ['should'], 'why': 'should is used for advice.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the modal verb.', 'prompt': 'Employees ___ wear a badge. (company rule)', 'hint': 'A rule or obligation.', 'answers': ['must', 'have to'], 'why': 'must / have to express obligation.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the modal verb.', 'prompt': 'I ___ speak three languages. (ability)', 'hint': 'Ability.', 'answers': ['can'], 'why': 'can expresses ability.'},
  ],
  'Conditionals': [
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'If it rains, we ___ (stay) home.', 'hint': 'A real possibility.', 'answers': ['will stay', "'ll stay"], 'why': 'First conditional: if + present, will + base verb.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'If I ___ (have) more time, I would learn French.', 'hint': 'Imaginary situation now.', 'answers': ['had'], 'why': 'Second conditional: if + past simple, would + base verb.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'If you heat ice, it ___ (melt).', 'hint': 'A general truth.', 'answers': ['melts'], 'why': 'Zero conditional (facts): if + present, present.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the correct form.', 'prompt': 'If we had planned earlier, we ___ (avoid) the problem.', 'hint': 'Past regret: would have + past participle.', 'answers': ['would have avoided', 'could have avoided'], 'why': 'Third conditional: if + past perfect, would have + past participle.'},
  ],
  'Passive Voice': [
    {'type': 'fill_blank', 'instruction': 'Fill in the passive form.', 'prompt': 'The report ___ (complete) by the team yesterday.', 'hint': 'was/were + past participle.', 'answers': ['was completed'], 'why': 'Past passive: was + past participle.'},
    {'type': 'transformation', 'instruction': 'Rewrite in the passive.', 'prompt': 'The company launched the product.', 'hint': 'The product...', 'answers': ['the product was launched by the company', 'the product was launched'], 'why': 'Object becomes the subject: was launched.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the passive form.', 'prompt': 'English ___ (speak) in many countries.', 'hint': 'Present passive.', 'answers': ['is spoken'], 'why': 'Present passive: is/are + past participle.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the passive form.', 'prompt': 'The emails ___ (send) tomorrow morning.', 'hint': 'Future passive.', 'answers': ['will be sent'], 'why': 'Future passive: will be + past participle.'},
  ],
  'Reported Speech': [
    {'type': 'fill_blank', 'instruction': 'Complete the reported sentence.', 'prompt': 'He said, "I am busy." → He said that he ___ busy.', 'hint': 'Step the tense back.', 'answers': ['was'], 'why': 'Reported speech moves the tense back: am → was.'},
    {'type': 'fill_blank', 'instruction': 'Complete the reported sentence.', 'prompt': 'She said, "I will call you." → She said she ___ call me.', 'hint': 'will → ?', 'answers': ['would'], 'why': 'will becomes would in reported speech.'},
    {'type': 'fill_blank', 'instruction': 'Complete the reported question.', 'prompt': 'The manager asked, "Did you finish?" → The manager asked me ___ I had finished.', 'hint': 'Yes/no question word.', 'answers': ['if', 'whether'], 'why': 'Reported yes/no questions use if or whether.'},
    {'type': 'fill_blank', 'instruction': 'Complete the reported sentence.', 'prompt': 'He said, "I work here." → He said he ___ there.', 'hint': 'Present → past.', 'answers': ['worked'], 'why': 'Present simple becomes past simple: work → worked.'},
  ],
  'Question Formation': [
    {'type': 'fill_blank', 'instruction': 'Fill in the question word.', 'prompt': '___ do you work? (asking about the place)', 'hint': 'Place.', 'answers': ['where'], 'why': 'Where asks about a place.'},
    {'type': 'transformation', 'instruction': 'Make a yes/no question.', 'prompt': 'She lives in Delhi.', 'hint': 'Start with Does.', 'answers': ['does she live in delhi'], 'why': 'Does + subject + base verb.'},
    {'type': 'fill_blank', 'instruction': 'Fill in the auxiliary verb.', 'prompt': '___ you call him yesterday?', 'hint': 'Past question.', 'answers': ['did'], 'why': 'Past simple questions use did.'},
    {'type': 'error_spotting', 'instruction': 'Rewrite the question correctly.', 'prompt': 'Where you are going?', 'hint': 'Check the word order.', 'answers': ['where are you going'], 'why': 'In questions the verb comes before the subject: Where are you going?'},
  ],
};

// ───────────────────────── TRAVEL KITS ─────────────────────────
// keys match kTravelSituations exactly. phrase pairs: [phrase, whenToUse]
const Map<String, Map<String, Object>> kLocalTravelKits = {
  'Airport & check-in': {
    'phrases': [
      ['I would like to check in for my flight to London.', 'At the airline counter'],
      ['Could I have a window seat, please?', 'Choosing a seat'],
      ['I have one bag to check in.', 'Handing over luggage'],
      ['What time does boarding start?', 'Asking about boarding'],
      ['Which gate is my flight departing from?', 'Finding your gate'],
      ['Excuse me, my flight has been delayed. What should I do?', 'When there is a delay'],
    ],
    'listenFor': ['"May I see your passport?"', '"Do you have any luggage to check in?"', '"Boarding starts at gate 12."'],
    'tip': 'Keep your passport and ticket ready — it makes every conversation faster.',
  },
  'Immigration & customs': {
    'phrases': [
      ['I am here for tourism.', 'Purpose of visit'],
      ['I will stay for ten days.', 'Length of stay'],
      ['I am staying at the Grand Hotel.', 'Where you are staying'],
      ['I have nothing to declare.', 'At customs'],
      ['Sorry, could you repeat that, please?', 'If you did not understand'],
      ['I am here on a business trip.', 'Business travel'],
    ],
    'listenFor': ['"What is the purpose of your visit?"', '"How long will you stay?"', '"Do you have anything to declare?"'],
    'tip': 'Answer calmly with short, clear sentences. Asking someone to repeat is completely normal.',
  },
  'Hotel check-in': {
    'phrases': [
      ['I have a reservation under the name Sharma.', 'At the front desk'],
      ['Could I have a room with a view, if possible?', 'Requesting a room'],
      ['What time is breakfast served?', 'Asking about meals'],
      ['Could you give me a wake-up call at 7 AM?', 'Requesting a service'],
      ['The air conditioning in my room is not working.', 'Reporting a problem'],
      ['What time is check-out?', 'Before leaving'],
    ],
    'listenFor': ['"How many nights are you staying?"', '"May I have a credit card for the deposit?"', '"Check-out is at 11 AM."'],
    'tip': 'When reporting a problem, state it clearly and politely, then ask for a solution.',
  },
  'Ordering at a restaurant': {
    'phrases': [
      ['A table for two, please.', 'When you arrive'],
      ['Could I see the menu, please?', 'Asking for the menu'],
      ["I'll have the grilled chicken, please.", 'Ordering'],
      ['Does this dish contain nuts?', 'Asking about ingredients'],
      ['Could we have the bill, please?', 'Asking for the bill'],
      ['Could I get this without onions?', 'Changing an order'],
    ],
    'listenFor': ['"Are you ready to order?"', '"Would you like something to drink?"', '"Is everything okay with your meal?"'],
    'tip': '"I\'ll have..." and "Could I get...?" sound natural and polite when ordering.',
  },
  'Asking for directions': {
    'phrases': [
      ['Excuse me, how do I get to the railway station?', 'Asking the way'],
      ['Is it far from here?', 'Asking about distance'],
      ['Could you show me on the map?', 'When directions are confusing'],
      ['Should I turn left or right at the signal?', 'Checking a direction'],
      ['Sorry, could you speak a little slower?', 'If they speak fast'],
      ['Is there a pharmacy near here?', 'Finding a place nearby'],
    ],
    'listenFor': ['"Go straight and turn left."', '"It is about a ten-minute walk."', '"It is opposite the bank."'],
    'tip': 'Repeat the directions back ("So I go straight, then turn left?") to confirm you understood.',
  },
  'Public transport & taxis': {
    'phrases': [
      ['Could you take me to the airport, please?', 'Telling a taxi driver'],
      ['How much will it cost to get there?', 'Asking the fare'],
      ['Which bus goes to the city center?', 'At a bus stop'],
      ['One ticket to Central Station, please.', 'Buying a ticket'],
      ['Could you stop here, please?', 'Getting off'],
      ['Does this train stop at Victoria?', 'Checking the route'],
    ],
    'listenFor': ['"Where to?"', '"That will be twenty dollars."', '"This train terminates at the next stop."'],
    'tip': 'Ask the price first when there is no meter — it avoids confusion later.',
  },
  'Shopping & bargaining': {
    'phrases': [
      ['How much is this?', 'Asking the price'],
      ['Do you have this in a larger size?', 'Asking for another size'],
      ['Could I try this on?', 'Trying clothes'],
      ['Is there any discount on this?', 'Asking for a discount'],
      ["That's a bit expensive. Could you do a better price?", 'Polite bargaining'],
      ["I'll take it. Can I pay by card?", 'Paying'],
    ],
    'listenFor': ['"It is fifty dollars."', '"We only accept cash."', '"Would you like a bag?"'],
    'tip': 'Stay friendly when bargaining — a smile and "Could you do a better price?" works better than pushing.',
  },
  'Emergency & getting help': {
    'phrases': [
      ['I need help, please.', 'Calling for help'],
      ['Could you call an ambulance?', 'Medical emergency'],
      ['I have lost my passport.', 'Reporting a loss'],
      ['Where is the nearest hospital?', 'Finding a hospital'],
      ['I do not speak much English. Could you help me?', 'When you need support'],
      ['My wallet has been stolen.', 'Reporting a theft'],
    ],
    'listenFor': ['"What is your name?"', '"Where are you right now?"', '"Please stay calm. Help is on the way."'],
    'tip': 'In an emergency, say the problem and your location first. Short, clear sentences are best.',
  },
};

// ───────────────────────── DAILY CHALLENGES ─────────────────────────
const List<Map<String, Object>> kLocalDailyChallenges = [
  {'minutes': 2, 'title': 'Describe your morning', 'type': 'speaking', 'why': 'A short warm-up builds speaking ease.', 'objective': 'Speak in connected sentences about your morning.', 'dailyGoal': 'Speak for 1 minute about your morning using at least 4 sentences.', 'steps': ['Think of what you did first.', 'Say 4 or more sentences in order.', 'Use words like first, then, after that.']},
  {'minutes': 5, 'title': 'Tell a short story', 'type': 'storytelling', 'why': 'Stories practise the past tense and connectors.', 'objective': 'Tell a simple past-tense story.', 'dailyGoal': 'Tell a 5-sentence story about an interesting day.', 'steps': ['Pick a memorable day.', 'Use past tense (went, saw, met).', 'Finish with how it ended.']},
  {'minutes': 5, 'title': 'Use 3 new words', 'type': 'vocabulary', 'why': 'Using words in speech makes them stick.', 'objective': 'Use new words naturally.', 'dailyGoal': 'Use deadline, reliable and improve in real sentences.', 'steps': ['Say one sentence for each word.', 'Make each sentence about your own life.', 'Say them again without looking.']},
  {'minutes': 10, 'title': 'Office small talk', 'type': 'roleplay', 'why': 'Small talk builds workplace confidence.', 'objective': 'Handle a friendly workplace conversation.', 'dailyGoal': 'Keep a 6-turn small talk conversation going.', 'steps': ['Greet a colleague.', 'Ask about their weekend or project.', 'Share one detail and ask a follow-up question.']},
  {'minutes': 10, 'title': 'Give a quick update', 'type': 'speaking', 'why': 'Status updates are a core work skill.', 'objective': 'Give a clear update using a simple structure.', 'dailyGoal': 'Give a 1-minute update: status, progress, issue, next step.', 'steps': ['Say the status in one sentence.', 'Mention progress and one issue.', 'End with your next step.']},
  {'minutes': 15, 'title': 'Opinion and reason', 'type': 'fluency', 'why': 'Opinions train spontaneous speaking.', 'objective': 'Give an opinion with a reason and an example.', 'dailyGoal': 'Speak for 2 minutes: opinion, reason, example.', 'steps': ['Choose: is remote work better?', 'Give your opinion in one sentence.', 'Add a reason and a real example.']},
  {'minutes': 15, 'title': 'Past tense practice', 'type': 'grammar', 'why': 'Past tense is a common error area to strengthen.', 'objective': 'Use past simple correctly while speaking.', 'dailyGoal': 'Describe your last weekend with 8 past-tense sentences.', 'steps': ['List 4 things you did.', 'Say each in the past tense.', 'Add when and where for each.']},
  {'minutes': 30, 'title': 'Mini interview', 'type': 'roleplay', 'why': 'Interview skills transfer to many situations.', 'objective': 'Answer common questions clearly.', 'dailyGoal': 'Answer "Tell me about yourself" in 60 seconds.', 'steps': ['Present: who you are now.', 'Past: your key experience.', 'Future: what you want next.']},
  {'minutes': 30, 'title': 'Explain your work', 'type': 'speaking', 'why': 'Explaining your job builds professional vocabulary.', 'objective': 'Explain your role to someone new.', 'dailyGoal': 'Explain your job in 2 minutes, simply and clearly.', 'steps': ['Say what you do in one sentence.', 'Describe a typical day.', 'Mention one challenge and how you handle it.']},
  {'minutes': 60, 'title': 'Full conversation session', 'type': 'fluency', 'why': 'Long practice builds stamina and confidence.', 'objective': 'Sustain a natural conversation.', 'dailyGoal': 'Hold a 10-minute conversation on any topic with the coach.', 'steps': ['Pick a topic you enjoy.', 'Ask the coach follow-up questions too.', 'Try not to switch to your first language.']},
];

// ───────────────────────── STARTER VOCABULARY ─────────────────────────
const List<Map<String, Object>> kStarterVocabulary = [
  {'word': 'deadline', 'category': 'word', 'meaning': 'the time or date by which something must be finished', 'simple': 'The last time you can finish a task.', 'examples': ['The deadline for the report is Friday.', 'We missed the deadline because of a delay.'], 'collocations': ['meet a deadline', 'miss a deadline', 'tight deadline'], 'register': 'neutral', 'nuance': 'Common at work and school.', 'practice': 'Make a sentence about a deadline you have this week.'},
  {'word': 'reliable', 'category': 'word', 'meaning': 'able to be trusted to do what you expect', 'simple': 'You can depend on this person or thing.', 'examples': ['She is a reliable colleague.', 'I need a reliable internet connection.'], 'collocations': ['reliable source', 'reliable person'], 'register': 'neutral', 'nuance': 'Similar: dependable, trustworthy.', 'practice': 'Describe someone reliable in your life.'},
  {'word': 'follow up', 'category': 'phrasal_verb', 'meaning': 'to contact someone again to check or continue something', 'simple': 'To check again about something you discussed.', 'examples': ["I'll follow up with the client tomorrow.", 'Just following up on my earlier email.'], 'collocations': ['follow up with someone', 'follow up on an email'], 'register': 'professional', 'nuance': 'Very common in work emails.', 'practice': 'Say how you would follow up after a meeting.'},
  {'word': 'look into', 'category': 'phrasal_verb', 'meaning': 'to investigate or check a problem', 'simple': 'To check what is going on.', 'examples': ["I'll look into the issue and get back to you.", 'We are looking into the delay.'], 'collocations': ['look into a problem', 'look into the matter'], 'register': 'neutral', 'nuance': 'More natural than "investigate" in conversation.', 'practice': 'Use look into to promise help with a problem.'},
  {'word': 'on the same page', 'category': 'idiom', 'meaning': 'sharing the same understanding', 'simple': 'Everyone understands in the same way.', 'examples': ["Let's make sure we're on the same page.", 'After the meeting, the team was on the same page.'], 'collocations': ['get on the same page', 'be on the same page'], 'register': 'informal-professional', 'nuance': 'Common in offices; do not overuse.', 'practice': 'Say it to check understanding with a colleague.'},
  {'word': 'negotiate', 'category': 'word', 'meaning': 'to discuss something to reach an agreement', 'simple': 'To talk until both sides agree.', 'examples': ['We negotiated a better price.', 'She is good at negotiating contracts.'], 'collocations': ['negotiate a deal', 'negotiate a price'], 'register': 'professional', 'nuance': 'Used in business and everyday bargaining.', 'practice': 'Describe something you negotiated.'},
  {'word': 'clarify', 'category': 'word', 'meaning': 'to make something clear', 'simple': 'To explain so it is easy to understand.', 'examples': ['Could you clarify what you mean?', 'Let me clarify the timeline.'], 'collocations': ['clarify a point', 'clarify the situation'], 'register': 'professional', 'nuance': 'A polite way to ask for more detail.', 'practice': 'Ask someone to clarify an instruction.'},
  {'word': 'appreciate', 'category': 'word', 'meaning': 'to be grateful for something', 'simple': 'To feel thankful.', 'examples': ['I really appreciate your help.', 'We appreciate your patience.'], 'collocations': ['really appreciate', 'appreciate your help'], 'register': 'neutral', 'nuance': 'Warmer than just "thanks".', 'practice': 'Thank someone using appreciate.'},
  {'word': 'confirm', 'category': 'word', 'meaning': 'to say that something is definitely true or arranged', 'simple': 'To make sure it is certain.', 'examples': ['Please confirm your attendance.', 'I can confirm the meeting is at 3 PM.'], 'collocations': ['confirm a booking', 'confirm receipt'], 'register': 'professional', 'nuance': 'Used a lot in emails and bookings.', 'practice': 'Confirm a time for a meeting.'},
  {'word': 'available', 'category': 'word', 'meaning': 'free to do something or able to be used', 'simple': 'Not busy; ready.', 'examples': ['Are you available tomorrow at 10?', 'This room is available after 5.'], 'collocations': ['be available', 'readily available'], 'register': 'neutral', 'nuance': 'Common when scheduling.', 'practice': 'Say when you are available this week.'},
  {'word': 'suggest', 'category': 'word', 'meaning': 'to offer an idea for someone to consider', 'simple': 'To give an idea.', 'examples': ['I suggest we start earlier.', 'She suggested a different approach.'], 'collocations': ['suggest an idea', 'suggest that we'], 'register': 'neutral', 'nuance': 'Pattern: suggest + that / suggest + -ing.', 'practice': 'Suggest a plan for the weekend.'},
  {'word': 'recommend', 'category': 'word', 'meaning': 'to say that something is good or suitable', 'simple': 'To say "this is a good choice".', 'examples': ['I recommend this restaurant.', 'What would you recommend?'], 'collocations': ['highly recommend', 'recommend a book'], 'register': 'neutral', 'nuance': 'Stronger than suggest.', 'practice': 'Recommend a place to a visitor.'},
  {'word': 'improve', 'category': 'word', 'meaning': 'to become or make something better', 'simple': 'To make better.', 'examples': ['I want to improve my English.', 'Sales have improved this quarter.'], 'collocations': ['improve skills', 'improve performance'], 'register': 'neutral', 'nuance': 'Works for people and things.', 'practice': 'Say one skill you want to improve.'},
  {'word': 'responsible', 'category': 'word', 'meaning': 'having the duty to do or take care of something', 'simple': 'It is your job or duty.', 'examples': ['I am responsible for the monthly report.', 'Who is responsible for this task?'], 'collocations': ['responsible for', 'take responsibility'], 'register': 'neutral', 'nuance': 'Pattern: responsible FOR something.', 'practice': 'Say what you are responsible for at work.'},
  {'word': 'opportunity', 'category': 'word', 'meaning': 'a chance to do something good', 'simple': 'A good chance.', 'examples': ['This is a great opportunity to learn.', 'Thank you for the opportunity.'], 'collocations': ['great opportunity', 'miss an opportunity'], 'register': 'neutral', 'nuance': 'Common in interviews.', 'practice': 'Describe an opportunity you want.'},
  {'word': 'concern', 'category': 'word', 'meaning': 'a worry or something that needs attention', 'simple': 'A worry.', 'examples': ['I have a concern about the timeline.', 'Please raise any concerns early.'], 'collocations': ['raise a concern', 'have a concern'], 'register': 'professional', 'nuance': 'More natural than "I have a doubt" at work.', 'practice': 'Politely raise a concern about a plan.'},
  {'word': 'update', 'category': 'word', 'meaning': 'new information about something; to give that information', 'simple': 'The latest news.', 'examples': ['Can you give me an update?', "I'll update you by 4 PM."], 'collocations': ['give an update', 'provide an update'], 'register': 'neutral', 'nuance': 'Both a noun and a verb.', 'practice': 'Give a quick update on your day.'},
  {'word': 'schedule', 'category': 'word', 'meaning': 'a plan of times for activities; to plan something for a time', 'simple': 'A plan with times.', 'examples': ["Let's schedule a call for Monday.", 'My schedule is full today.'], 'collocations': ['tight schedule', 'schedule a meeting'], 'register': 'neutral', 'nuance': 'Noun and verb.', 'practice': 'Schedule a meeting out loud.'},
  {'word': 'achieve', 'category': 'word', 'meaning': 'to succeed in reaching a goal', 'simple': 'To reach a goal.', 'examples': ['She achieved her sales target.', 'What do you want to achieve this year?'], 'collocations': ['achieve a goal', 'achieve results'], 'register': 'neutral', 'nuance': 'Used for goals and results.', 'practice': 'Say one goal you want to achieve.'},
  {'word': 'support', 'category': 'word', 'meaning': 'to help someone or something; help given', 'simple': 'To help.', 'examples': ['Thank you for your support.', 'My team supports me a lot.'], 'collocations': ['provide support', 'support a decision'], 'register': 'neutral', 'nuance': 'Noun and verb.', 'practice': 'Ask a colleague for support politely.'},
];
