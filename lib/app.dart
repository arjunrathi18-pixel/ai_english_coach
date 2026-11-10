import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_controller.dart';
import 'main_shell.dart';

class AiEnglishCoachApp extends StatefulWidget {
  const AiEnglishCoachApp({super.key});

  @override
  State<AiEnglishCoachApp> createState() => _AiEnglishCoachAppState();
}

class _AiEnglishCoachAppState extends State<AiEnglishCoachApp> {
  @override
  void initState() {
    super.initState();
    themeController.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'AI English Coach',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          home: const MainShell(),
        );
      },
    );
  }
}
