import 'package:flutter/material.dart';

/// Centralized design tokens — semantic colors, spacing, radius, motion.
/// Screens should reference these (or the ThemeData built from them in
/// app_theme.dart) rather than hard-coding raw color/spacing values.
class AppColors {
  // ---- Dark theme ----
  static const darkBackground = Color(0xFF0F1117);
  static const darkSurface = Color(0xFF1A1F2A);
  static const darkSurfaceElevated = Color(0xFF202633);
  static const darkTextPrimary = Color(0xFFF5F7FA);
  static const darkTextSecondary = Color(0xFFA7AFBD);
  static const darkTextMuted = Color(0xFF707887);
  static const darkBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // ---- Light theme ----
  static const lightBackground = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF161922);
  static const lightTextSecondary = Color(0xFF5E6573);
  static const lightTextMuted = Color(0xFF8B92A0);
  static const lightBorder = Color(0x0F000000); // rgba(0,0,0,0.06)

  // ---- Shared brand accents (same in both themes) ----
  static const accentPrimary = Color(0xFF6C63FF); // indigo
  static const accentSecondary = Color(0xFF4FD1FF); // cyan highlight
  static const success = Color(0xFF35D07F);
  static const warning = Color(0xFFF5B942);
  static const error = Color(0xFFFF5C6C);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const massive = 48.0;
}

class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const card = 20.0;
  static const hero = 24.0;
}

class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
