import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final String selectedMode; // friend | tutor | coach
  final ValueChanged<String> onChanged;

  const ModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  static const _modes = [
    {'key': 'friend', 'label': 'Friend', 'emoji': '🧑\u200d🤝\u200d🧑'},
    {'key': 'tutor', 'label': 'Tutor', 'emoji': '👨\u200d🏫'},
    {'key': 'coach', 'label': 'Coach', 'emoji': '🎯'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = _modes[i];
          final isSelected = m['key'] == selectedMode;
          return ChoiceChip(
            label: Text('${m['emoji']} ${m['label']}'),
            selected: isSelected,
            onSelected: (_) => onChanged(m['key']!),
          );
        },
      ),
    );
  }
}
