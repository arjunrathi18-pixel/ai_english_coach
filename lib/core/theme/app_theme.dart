import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2F6FED);
  static const Color aiBubble = Color(0xFFEFF3FF);
  static const Color userBubble = Color(0xFF2F6FED);
  static const Color background = Color(0xFFFAFAFC);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }
}
