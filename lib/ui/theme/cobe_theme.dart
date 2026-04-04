// cobe_theme.dart — Midnight Black Glassmorphism tokens
import 'package:flutter/material.dart';

abstract final class CobeColors {
  static const bg          = Color(0xFF080A0F);
  static const surface     = Color(0xFF0D1017);
  static const glass       = Color(0x18FFFFFF);
  static const glassBorder = Color(0x30FFFFFF);
  static const glassDeep   = Color(0x0AFFFFFF);
  static const pulse       = Color(0xFF6366F1); // indigo glow
  static const pulseAlt    = Color(0xFF8B5CF6); // violet
  static const accent      = Color(0xFF22D3EE); // cyan
  static const error       = Color(0xFFEF4444);
  static const warning     = Color(0xFFF59E0B);
  static const success     = Color(0xFF10B981);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSub     = Color(0xFF64748B);
  static const ghostText   = Color(0xFF334155);
  static const dotDirty    = Color(0xFF3B82F6); // blue dirty dot
  static const divider     = Color(0x14FFFFFF);
}

abstract final class CobeTextStyles {
  static const mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: CobeColors.textPrimary,
    fontSize: 13,
    height: 1.6,
  );
  static const monoGhost = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: CobeColors.ghostText,
    fontSize: 13,
    height: 1.6,
    fontStyle: FontStyle.italic,
  );
  static const ui = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: CobeColors.textPrimary,
    fontSize: 14,
  );
  static const uiSub = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: CobeColors.textSub,
    fontSize: 12,
  );
  static const label = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: CobeColors.accent,
    fontSize: 11,
    letterSpacing: 0.8,
  );
}

ThemeData cobeTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CobeColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: CobeColors.surface,
        primary: CobeColors.pulse,
        secondary: CobeColors.accent,
        error: CobeColors.error,
      ),
      fontFamily: 'JetBrainsMono',
      dividerColor: CobeColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: CobeTextStyles.ui,
      ),
      textTheme: const TextTheme(
        bodyMedium: CobeTextStyles.ui,
        bodySmall: CobeTextStyles.uiSub,
        labelSmall: CobeTextStyles.label,
      ),
    );
