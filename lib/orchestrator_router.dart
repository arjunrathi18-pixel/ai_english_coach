import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'daily_challenge_screen.dart';
import 'roleplay_setup_screen.dart';
import 'interview_setup_screen.dart';
import 'meeting_screen.dart';
import 'email_coach_screen.dart';
import 'grammar_lab_screen.dart';
import 'vocabulary_screen.dart';
import 'listening_screen.dart';
import 'pronunciation_hub_screen.dart';
import 'fluency_lab_screen.dart';
import 'think_in_english_screen.dart';
import 'presentation_screen.dart';
import 'debate_screen.dart';
import 'travel_hub_screen.dart';
import 'review_session_screen.dart';
import 'progress_dashboard_screen.dart';
import 'learner_memory_screen.dart';
import 'voice_personality_settings_screen.dart';
import 'assessment_screen.dart';
import 'goal_selector_screen.dart';
import 'say_it_better_screen.dart';

/// Single place that maps an intent key (from the Orchestrator) to the
/// experience that serves it. Returns null for "none"/unknown intents.
class OrchestratorRouter {
  static Widget? screenFor(String intent) {
    switch (intent) {
      case 'friend_chat':
        return const ChatScreen(initialMode: 'friend');
      case 'tutor_chat':
        return const ChatScreen(initialMode: 'tutor');
      case 'coach_chat':
        return const ChatScreen(initialMode: 'coach');
      case 'daily_challenge':
        return const DailyChallengeScreen();
      case 'roleplay':
        return const RoleplaySetupScreen();
      case 'interview':
        return const InterviewSetupScreen();
      case 'business_meeting':
        return const MeetingScreen();
      case 'email_coach':
        return const EmailCoachScreen();
      case 'grammar':
        return const GrammarLabScreen();
      case 'vocabulary':
        return const VocabularyScreen();
      case 'listening':
        return const ListeningScreen();
      case 'pronunciation':
        return const PronunciationHubScreen();
      case 'fluency':
        return const FluencyLabScreen();
      case 'think_in_english':
        return const ThinkInEnglishScreen();
      case 'presentation':
        return const PresentationScreen();
      case 'debate':
        return const DebateScreen();
      case 'travel':
        return const TravelHubScreen();
      case 'review':
        return const ReviewSessionScreen();
      case 'progress':
        return const ProgressDashboardScreen();
      case 'memory':
        return const LearnerMemoryScreen();
      case 'settings':
        return const VoicePersonalitySettingsScreen();
      case 'assessment':
        return const AssessmentScreen();
      case 'goal':
        return const GoalSelectorScreen();
      case 'say_it_better':
        return const SayItBetterScreen();
      default:
        return null;
    }
  }
}
