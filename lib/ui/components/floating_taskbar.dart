import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/cobe_tokens.dart';

class FloatingTaskbar extends StatefulWidget {
  const FloatingTaskbar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  State<FloatingTaskbar> createState() => _FloatingTaskbarState();
}

class _FloatingTaskbarState extends State<FloatingTaskbar> {
  Offset _offset = const Offset(20, 0);
  double _opacity = 1;
  Timer? _fadeTimer;

  static const _items = [
    (label: 'Settings', icon: Icons.tune_rounded),
    (label: 'History', icon: Icons.history_rounded),
    (label: 'Home', icon: Icons.home_rounded),
    (label: 'Diff', icon: Icons.compare_arrows_rounded),
    (label: 'Editor', icon: Icons.code_rounded),
  ];

  void _scheduleFade() {
    _fadeTimer?.cancel();
    _opacity = 1;
    _fadeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _opacity = 0.35);
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleFade();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    final width = MediaQuery.sizeOf(context).width;
    final leftCap = width - 280;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 220),
      child: GestureDetector(
        onPanStart: (_) => setState(() => _opacity = 1),
        onPanUpdate: (details) {
          setState(() {
            _offset = Offset(
              (_offset.dx + details.delta.dx).clamp(8, leftCap),
              0,
            );
          });
        },
        onPanEnd: (_) {
          final snapLeft = _offset.dx < width / 2;
          setState(() => _offset = Offset(snapLeft ? 8 : leftCap, 0));
          _scheduleFade();
        },
        child: Padding(
          padding: EdgeInsets.only(left: _offset.dx),
          child: Container(
            padding: const EdgeInsets.all(CobeSpacing.xs),
            decoration: BoxDecoration(
              color: t.bgPanel.withValues(alpha: 0.96),
              borderRadius: CobeRadius.pill,
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _TaskbarItem(
                    label: _items[i].label,
                    icon: _items[i].icon,
                    active: widget.activeIndex == i,
                    onTap: () {
                      widget.onTap(i);
                      _scheduleFade();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskbarItem extends StatelessWidget {
  const _TaskbarItem({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: CobeRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: CobeSpacing.sm, vertical: CobeSpacing.xs),
        decoration: BoxDecoration(
          color: active ? t.accent : Colors.transparent,
          borderRadius: CobeRadius.pill,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? t.bgBase : t.textPrimary),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 8.5, color: active ? t.bgBase : t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
