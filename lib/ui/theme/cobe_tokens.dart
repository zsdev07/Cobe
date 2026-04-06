import 'package:flutter/widgets.dart';

@immutable
class CobeTokens {
  const CobeTokens({
    required this.bgBase,
    required this.bgPanel,
    required this.bgCard,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.border,
    required this.glow,
  });

  final Color bgBase;
  final Color bgPanel;
  final Color bgCard;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color border;
  final Color glow;

  static const CobeTokens dark = CobeTokens(
    bgBase: Color(0xFF050505),
    bgPanel: Color(0xFF0C0C0E),
    bgCard: Color(0xFF111114),
    textPrimary: Color(0xFFF3F3F4),
    textMuted: Color(0xFFA4A4AE),
    accent: Color(0xFFE3E3EA),
    border: Color(0xFF1F1F25),
    glow: Color(0x2EB8B8FF),
  );
}

class CobeSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class CobeRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}
