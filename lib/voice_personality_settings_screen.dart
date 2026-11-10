import 'package:flutter/material.dart';
import 'ai_personality.dart';
import 'conversation_length.dart';
import 'correction_intensity.dart';
import 'voice_personality_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

class VoicePersonalitySettingsScreen extends StatefulWidget {
  const VoicePersonalitySettingsScreen({super.key});

  @override
  State<VoicePersonalitySettingsScreen> createState() => _VoicePersonalitySettingsScreenState();
}

class _VoicePersonalitySettingsScreenState extends State<VoicePersonalitySettingsScreen> {
  AiPersonality _personality = AiPersonality.friendly;
  String _accent = 'indian';
  CorrectionIntensity _correction = CorrectionIntensity.balanced;
  ConversationLength _length = ConversationLength.normal;
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    VoicePersonalityStore.loadDefaults().then((s) {
      setState(() {
        _personality = s.personality;
        _accent = s.accent;
        _correction = s.correctionIntensity;
        _length = s.conversationLength;
        _loading = false;
      });
    });
  }

  Future<void> _save() async {
    await VoicePersonalityStore.save(
      personality: _personality,
      accent: _accent,
      correctionIntensity: _correction,
      conversationLength: _length,
    );
    setState(() => _saved = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved — these will be your defaults in every session.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Voice & Personality')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SectionHeader(title: 'AI Personality'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AiPersonality.values.map((p) => ChoiceChip(
                  label: Text(p.label),
                  selected: _personality == p,
                  onSelected: (_) => setState(() => _personality = p),
                )).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'English Variety'),
          const SizedBox(height: 4),
          Text(
            'Treated as equally valid — this only changes examples and the voice.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Indian'), selected: _accent == 'indian', onSelected: (_) => setState(() => _accent = 'indian')),
              ChoiceChip(label: const Text('American'), selected: _accent == 'american', onSelected: (_) => setState(() => _accent = 'american')),
              ChoiceChip(label: const Text('British'), selected: _accent == 'british', onSelected: (_) => setState(() => _accent = 'british')),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Correction Intensity'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: CorrectionIntensity.values.map((c) => ChoiceChip(
                  label: Text(c.label),
                  selected: _correction == c,
                  onSelected: (_) => setState(() => _correction = c),
                )).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Conversation Length'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConversationLength.values.map((l) => ChoiceChip(
                  label: Text('${l.label} (${l.description})'),
                  selected: _length == l,
                  onSelected: (_) => setState(() => _length = l),
                )).toList(),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(label: _saved ? 'Saved ✓' : 'Save as Defaults', icon: Icons.check, onPressed: _save),
        ],
      ),
    );
  }
}
