import 'package:flutter/material.dart';
import 'travel_prompts.dart';
import 'travel_service.dart';
import 'daily_session.dart';
import 'chat_screen.dart';
import 'profile_store.dart';
import 'speech_service.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class TravelHubScreen extends StatefulWidget {
  const TravelHubScreen({super.key});

  @override
  State<TravelHubScreen> createState() => _TravelHubScreenState();
}

class _TravelHubScreenState extends State<TravelHubScreen> {
  final TravelService _service = TravelService();
  final SpeechService _speech = SpeechService();
  String _level = 'unknown';
  TravelKit? _kit;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _speech.init();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  Future<void> _open(String situation) async {
    setState(() => _loading = true);
    final kit = await _service.buildKit(situation: situation, level: _level);
    setState(() {
      _kit = kit;
      _loading = false;
    });
  }

  void _practice() {
    final plan = DailySessionPlan(
      lessonType: 'Travel: ${_kit!.situation}',
      level: _level,
      objective: 'Roleplay a realistic "${_kit!.situation}" situation as a traveler.',
      structure: [],
      dailyGoal: 'Use at least 3 phrases from the kit naturally.',
      totalMinutes: 10,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        initialEstimatedLevel: _level == 'unknown' ? null : _level,
        sessionPlan: plan,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_kit == null ? 'Travel English' : _kit!.situation),
        leading: _kit == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _kit = null)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kit == null
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: kTravelSituations
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AppActionCard(
                              icon: Icons.flight_takeoff_outlined,
                              title: s,
                              subtitle: 'Get a phrase kit',
                              onTap: () => _open(s),
                            ),
                          ))
                      .toList(),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    const SectionHeader(title: 'Useful Phrases'),
                    const SizedBox(height: AppSpacing.md),
                    ..._kit!.phrases.map((p) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(p.phrase),
                            subtitle: Text(p.whenToUse),
                            trailing: IconButton(
                              icon: const Icon(Icons.volume_up_outlined),
                              onPressed: () => _speech.speak(p.phrase),
                            ),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'Listen For'),
                    const SizedBox(height: AppSpacing.md),
                    ..._kit!.listenFor.map((l) => Text('• $l')),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Text(_kit!.tip, style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(label: 'Practice This Situation', icon: Icons.play_arrow, onPressed: _practice),
                  ],
                ),
    );
  }
}
