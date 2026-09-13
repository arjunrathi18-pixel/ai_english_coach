# AI English Coach — Flutter App

Voice-first AI English speaking tutor. This repo is built incrementally,
prompt by prompt, following the app's system-prompt design doc. Right now
it contains **Prompt 1: Core Tutor Master Brain**.

## What's included so far

- `lib/core/constants/system_prompts.dart` — the Master Brain system prompt
  and session-context builder. This is what makes the AI behave like a
  tutor instead of a generic chatbot.
- `lib/services/ai_tutor_service.dart` — calls the Anthropic API with the
  system prompt + conversation history.
- `lib/services/speech_service.dart` — mic input (speech-to-text) and
  spoken replies (text-to-speech).
- `lib/screens/home_screen.dart`, `chat_screen.dart` — home screen and the
  main voice/text conversation screen.
- `lib/widgets/` — chat bubbles, Friend/Tutor/Coach mode selector.
- `lib/models/` — chat message + session settings.

## How to turn this into a runnable Flutter project

This zip has the `lib/` source and a **reference** Android manifest, but not
the full platform scaffolding (the generated `android/`, `ios/` build
folders Flutter needs). To get a buildable project:

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Create a fresh Flutter project shell, then copy this `lib/` folder in:
   ```bash
   flutter create ai_english_coach
   cd ai_english_coach
   # replace the generated lib/ with the one from this zip
   rm -rf lib
   cp -r /path/to/this/zip/lib .
   cp /path/to/this/zip/pubspec.yaml .
   ```
3. Merge the permissions from this zip's `android/app/src/main/AndroidManifest.xml`
   into the one `flutter create` generated for you (don't just overwrite it —
   your generated one has required Flutter boilerplate this reference
   doesn't).
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run with your Anthropic API key (never commit this key to GitHub):
   ```bash
   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```
6. Push to GitHub as normal. Add a `.gitignore` entry so you never commit
   real API keys — use `--dart-define` at build/run time, or a secrets
   manager, instead of hardcoding.

## Next steps

Every following prompt in the sequence (Level Assessment, Personalization
Engine, Friend/Teacher conversation engines, Pronunciation, Accents,
Roleplay, Interview Simulator, etc.) will add new files into this same
project — mainly new prompt constants in `system_prompts.dart`, new
services, and new screens/widgets. Nothing here needs to be thrown away.
