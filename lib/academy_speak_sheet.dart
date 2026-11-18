import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'recognition_result.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Word-level comparison of what the learner said (device speech-to-text
/// transcript) against the expected sentence. This is a plain text
/// comparison — NOT a pronunciation score, and it makes no claim about
/// sounds, stress or intonation.
class SpeakCompareResult {
  final List<String> matched;
  final List<String> missing;
  final List<String> extra;
  const SpeakCompareResult(this.matched, this.missing, this.extra);
  bool get allMatched => missing.isEmpty && extra.isEmpty;
}

List<String> _words(String s) => s
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

SpeakCompareResult compareSpoken(String expected, String heard) {
  final exp = _words(expected);
  final got = [..._words(heard)];
  final matched = <String>[];
  final missing = <String>[];
  for (final w in exp) {
    final i = got.indexOf(w);
    if (i >= 0) {
      matched.add(w);
      got.removeAt(i);
    } else {
      missing.add(w);
    }
  }
  return SpeakCompareResult(matched, missing, got);
}

/// Bottom sheet: listen to the model sentence (device TTS), speak it, and
/// see the recognised transcript compared word by word.
class SpeakCompareSheet extends StatefulWidget {
  final String expected;
  final VoidCallback? onAttempted;
  const SpeakCompareSheet({super.key, required this.expected, this.onAttempted});

  static Future<void> show(BuildContext context, String expected, {VoidCallback? onAttempted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SpeakCompareSheet(expected: expected, onAttempted: onAttempted),
    );
  }

  @override
  State<SpeakCompareSheet> createState() => _SpeakCompareSheetState();
}

class _SpeakCompareSheetState extends State<SpeakCompareSheet> {
  final SpeechService _speech = SpeechService();
  bool _listening = false;
  bool _ready = false;
  String _heard = '';
  SpeakCompareResult? _result;
  String? _note;

  @override
  void initState() {
    super.initState();
    _speech.init().then((ok) {
      if (!mounted) return;
      setState(() {
        _ready = ok;
        if (!ok) _note = 'Speech recognition is not available on this device (or microphone permission was denied).';
      });
    });
  }

  @override
  void dispose() {
    _speech.stopListening();
    _speech.stopSpeaking();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_ready) return;
    setState(() {
      _listening = true;
      _heard = '';
      _result = null;
    });
    await _speech.startListeningDetailed(onResult: (r) {
      if (!mounted) return;
      setState(() => _heard = r.transcript);
      if (r.isFinal) {
        setState(() {
          _listening = false;
          _result = compareSpoken(widget.expected, r.transcript);
        });
        widget.onAttempted?.call();
      }
    });
  }

  Future<void> _stop() async {
    await _speech.stopListening();
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (_heard.trim().isNotEmpty) {
        _result = compareSpoken(widget.expected, _heard);
        widget.onAttempted?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Say this sentence', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(widget.expected, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Listen', icon: Icons.volume_up_outlined, onPressed: () => _speech.speak(widget.expected))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: _listening ? 'Stop' : 'Speak',
                  icon: _listening ? Icons.stop : Icons.mic,
                  onPressed: _ready ? (_listening ? _stop : _listen) : null,
                ),
              ),
            ],
          ),
          if (_note != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_note!, style: theme.textTheme.bodySmall),
          ],
          if (_heard.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Recognised by your device:', style: theme.textTheme.labelLarge),
            Text('"$_heard"', style: theme.textTheme.bodyMedium),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _result!.allMatched
                  ? 'Every word matched the expected sentence.'
                  : 'Matched ${_result!.matched.length} of ${_result!.matched.length + _result!.missing.length} words.',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: _result!.allMatched ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700),
            ),
            if (_result!.missing.isNotEmpty) Text('Not heard: ${_result!.missing.join(', ')}', style: theme.textTheme.bodySmall),
            if (_result!.extra.isNotEmpty) Text('Extra words heard: ${_result!.extra.join(', ')}', style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'This compares words only. It is not a pronunciation score — microphone quality, noise and the '
            'recogniser can all affect the result.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
