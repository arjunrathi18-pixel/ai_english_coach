import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_screen.dart';

class AiEnglishCoachApp extends StatelessWidget {
  const AiEnglishCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI English Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
