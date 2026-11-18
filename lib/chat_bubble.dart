import 'package:flutter/material.dart';
import 'chat_message.dart';
import 'design_tokens.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.sender == SenderType.user;

    final bubbleColor = isUser
        ? AppColors.accentPrimary
        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface);
    final textColor = isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: isUser ? null : Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.large),
            topRight: const Radius.circular(AppRadius.large),
            bottomLeft: Radius.circular(isUser ? AppRadius.large : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.large),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 15.5, height: 1.35),
        ),
      ),
    );
  }
}
