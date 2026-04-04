// glass_widgets.dart — Glassmorphism primitives + Pulse indicators
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/cobe_theme.dart';

// ── Glass Panel ───────────────────────────────────────────────────────────
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? radius;
  final bool pulsing;

  const GlassPanel({
    super.key,
    required this.child,
    this.blurSigma = 18,
    this.padding,
    this.radius,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(16);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        borderRadius: br,
        border: Border.all(
          color: pulsing
              ? CobeColors.pulse.withOpacity(0.6)
              : CobeColors.glassBorder,
          width: pulsing ? 1.5 : 1.0,
        ),
        boxShadow: pulsing
            ? [
                BoxShadow(
                  color: CobeColors.pulse.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: CobeColors.glass,
              borderRadius: br,
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Pulse Glow Border ─────────────────────────────────────────────────────
class PulseGlowBorder extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;

  const PulseGlowBorder({
    super.key,
    required this.child,
    this.active = false,
    this.color = CobeColors.pulse,
  });

  @override
  State<PulseGlowBorder> createState() => _PulseGlowBorderState();
}

class _PulseGlowBorderState extends State<PulseGlowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.15, end: 0.65).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_anim.value),
              blurRadius: 32,
              spreadRadius: 1,
            )
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── Dirty Dot (Blue Dot) ─────────────────────────────────────────────────
class DirtyDot extends StatelessWidget {
  final bool visible;
  const DirtyDot({super.key, this.visible = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          color: CobeColors.dotDirty,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Status Bar ─────────────────────────────────────────────────────────────
class CobeStatusBar extends StatelessWidget {
  final String message;
  final bool indexing;

  const CobeStatusBar({
    super.key,
    required this.message,
    this.indexing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: const Color(0xFF050709),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (indexing) ...[
            _PulseDot(color: CobeColors.pulse),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              message,
              style: CobeTextStyles.uiSub,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.4 + 0.6 * _c.value),
        ),
      ),
    );
  }
}

// ── Frost/Melt Overlay (Panic animation) ──────────────────────────────────
class FrostOverlay extends StatefulWidget {
  final bool active;
  const FrostOverlay({super.key, required this.active});
  @override
  State<FrostOverlay> createState() => _FrostOverlayState();
}

class _FrostOverlayState extends State<FrostOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }
  @override
  void didUpdateWidget(FrostOverlay o) {
    super.didUpdateWidget(o);
    if (widget.active) _c.forward();
    else _c.reverse();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        if (_c.value == 0) return const SizedBox.shrink();
        return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 40 * _c.value, sigmaY: 40 * _c.value),
          child: Container(
            color: Colors.white.withOpacity(0.04 * _c.value),
            child: Center(
              child: Opacity(
                opacity: _c.value,
                child: const Text('🔒 Secured',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontFamily: 'JetBrainsMono')),
              ),
            ),
          ),
        );
      },
    );
  }
}
