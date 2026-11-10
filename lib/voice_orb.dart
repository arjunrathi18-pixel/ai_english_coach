import 'package:flutter/material.dart';
import 'design_tokens.dart';

enum VoiceOrbState { idle, listening, thinking, speaking, error }

/// A single, reusable visual for "is the AI listening / thinking /
/// speaking / has my mic input worked" — used wherever voice interaction
/// happens (Chat, Roleplay, Interview) so the app has one consistent AI
/// visual language instead of a plain mic icon (Prompt 11, sections 17,
/// 19, 66, 67).
///
/// This is also the tappable mic button itself — pass [onTap].
class VoiceOrb extends StatefulWidget {
  final VoiceOrbState state;
  final VoidCallback? onTap;
  final double size;

  const VoiceOrb({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 64,
  });

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _color() {
    switch (widget.state) {
      case VoiceOrbState.idle:
        return AppColors.accentPrimary;
      case VoiceOrbState.listening:
        return AppColors.accentSecondary;
      case VoiceOrbState.thinking:
        return AppColors.accentPrimary;
      case VoiceOrbState.speaking:
        return AppColors.success;
      case VoiceOrbState.error:
        return AppColors.error;
    }
  }

  IconData _icon() {
    switch (widget.state) {
      case VoiceOrbState.idle:
        return Icons.mic_none_rounded;
      case VoiceOrbState.listening:
        return Icons.graphic_eq_rounded;
      case VoiceOrbState.thinking:
        return Icons.auto_awesome_rounded;
      case VoiceOrbState.speaking:
        return Icons.volume_up_rounded;
      case VoiceOrbState.error:
        return Icons.mic_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    // Idle: very subtle breathing. Listening/speaking: livelier pulse.
    // Thinking: gentle continuous rotation of the glow. Error: static.
    final isAnimated = widget.state != VoiceOrbState.error;
    final minScale = widget.state == VoiceOrbState.idle ? 0.97 : 0.92;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = isAnimated ? _controller.value : 0.0;
          final scale = minScale + (1.0 - minScale) * t;
          return Transform.scale(
            scale: widget.state == VoiceOrbState.thinking ? 1.0 : scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(widget.state == VoiceOrbState.idle ? 0.25 : 0.4 + 0.2 * t),
                    color.withOpacity(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 16 + (isAnimated ? 10 * t : 0),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: widget.size * 0.62,
                  height: widget.size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: Icon(_icon(), color: Colors.white, size: widget.size * 0.32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
