import 'package:flutter/material.dart';

import '../components/cobe_surface.dart';
import '../theme/cobe_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<(String, List<String>)> groups = [
    ('Providers', ['API Keys', 'AI Models']),
    ('Chat', ['Prompt Editing', 'Streaming Controls']),
    ('Vibe Code Editor', ['Vision Models', 'Editor Density']),
    ('UI', ['Theme', 'Colors', 'Spacing', 'Layout', 'Split View', 'Screen Scaling']),
    ('Floating Taskbar', ['Position', 'Fade', 'Gesture Sensitivity']),
    ('Notifications', ['Tasks', 'Errors', 'Updates']),
    ('Command Palette', ['Enable', 'Shortcuts']),
    ('Quick Actions', ['Context Actions', 'Toolbar Actions']),
    ('Gestures', ['Swipe Actions', 'Long Press']),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CobeSpacing.md, CobeSpacing.md, CobeSpacing.md, 86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: CobeSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: CobeSpacing.sm),
              itemBuilder: (context, index) {
                final group = groups[index];
                return CobeSurface(
                  padding: const EdgeInsets.all(CobeSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: CobeSpacing.xs),
                      for (final entry in group.$2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _SettingsRow(label: entry),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CobeTokens.dark.bgPanel,
        borderRadius: CobeRadius.sm,
        border: Border.all(color: CobeTokens.dark.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: CobeSpacing.sm, vertical: CobeSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: CobeTokens.dark.textPrimary))),
          Icon(Icons.chevron_right_rounded, size: 16, color: CobeTokens.dark.textMuted),
        ],
      ),
    );
  }
}
