import 'package:flutter/material.dart';

import 'cobe_tokens.dart';

ThemeData buildCobeTheme() {
  const t = CobeTokens.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: t.bgBase,
    fontFamily: 'JetBrainsMono',
    colorScheme: const ColorScheme.dark(
      primary: t.accent,
      secondary: t.textMuted,
      surface: t.bgPanel,
      onSurface: t.textPrimary,
      onPrimary: Color(0xFF040404),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.35),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.35),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    dividerColor: t.border,
  );
}
