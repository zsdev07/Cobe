// hover_menu.dart — Draggable snapping circular/horizontal Hover Menu
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../theme/cobe_theme.dart';
import 'glass_widgets.dart';
import 'dart:math' as math;

class HoverMenu extends ConsumerWidget {
  const HoverMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hoverMenuProvider);
    if (!state.visible) return const SizedBox.shrink();

    return Positioned(
      left: state.x,
      top: state.y,
      child: GestureDetector(
        onPanUpdate: (d) {
          final size = MediaQuery.of(context).size;
          final nx = (state.x + d.delta.dx).clamp(0.0, size.width - 60);
          final ny = (state.y + d.delta.dy).clamp(0.0, size.height - 60);
          ref.read(hoverMenuProvider.notifier).move(nx, ny);
        },
        onPanEnd: (_) => _snap(context, ref, state),
        child: state.circular
            ? _CircularMenu(ref: ref)
            : _HorizontalMenu(ref: ref),
      ),
    );
  }

  void _snap(BuildContext ctx, WidgetRef ref, HoverMenuState s) {
    final size = MediaQuery.of(ctx).size;
    final snapX = s.x < size.width / 2 ? 16.0 : size.width - 76.0;
    ref.read(hoverMenuProvider.notifier).move(snapX, s.y);
  }
}

class _CircularMenu extends StatelessWidget {
  final WidgetRef ref;
  const _CircularMenu({required this.ref});

  static const _items = [
    (Icons.folder_open_rounded, 'Files'),
    (Icons.smart_toy_outlined,  'AI'),
    (Icons.terminal_rounded,    'Term'),
    (Icons.settings_outlined,   'Settings'),
    (Icons.diff_outlined,       'Diff'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GlassPanel(
            padding: EdgeInsets.zero,
            radius: BorderRadius.circular(65),
            child: const SizedBox(width: 60, height: 60),
          ),
          ..._items.asMap().entries.map((e) {
            final angle = (e.key / _items.length) * 2 * math.pi - math.pi / 2;
            const r = 48.0;
            return Positioned(
              left: 65 + r * math.cos(angle) - 16,
              top:  65 + r * math.sin(angle) - 16,
              child: _MenuBtn(icon: e.value.$1, label: e.value.$2),
            );
          }),
        ],
      ),
    );
  }
}

class _HorizontalMenu extends StatelessWidget {
  final WidgetRef ref;
  const _HorizontalMenu({required this.ref});

  static const _items = [
    (Icons.folder_open_rounded, 'Files'),
    (Icons.smart_toy_outlined,  'AI'),
    (Icons.terminal_rounded,    'Term'),
    (Icons.settings_outlined,   'Cfg'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      radius: BorderRadius.circular(32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items
            .map((i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _MenuBtn(icon: i.$1, label: i.$2),
                ))
            .toList(),
      ),
    );
  }
}

class _MenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CobeColors.glassDeep,
            border: Border.all(color: CobeColors.glassBorder),
          ),
          child: Icon(icon, size: 16, color: CobeColors.textPrimary),
        ),
      ),
    );
  }
}
