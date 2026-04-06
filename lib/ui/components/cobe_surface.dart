import 'package:flutter/material.dart';

import '../theme/cobe_tokens.dart';

class CobeSurface extends StatelessWidget {
  const CobeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CobeSpacing.md),
    this.margin = EdgeInsets.zero,
    this.radius = CobeRadius.md,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: radius,
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(color: t.glow, blurRadius: 20, spreadRadius: 0.3),
        ],
      ),
      child: child,
    );
  }
}
