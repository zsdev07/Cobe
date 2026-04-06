import 'package:flutter/material.dart';

import '../components/cobe_surface.dart';
import '../theme/cobe_tokens.dart';

class DiffScreen extends StatelessWidget {
  const DiffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CobeSpacing.md, CobeSpacing.md, CobeSpacing.md, 86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diff', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: CobeSpacing.sm),
          const Text('lib/ui/screens/chat_screen.dart', style: TextStyle(fontSize: 11, color: CobeTokens.dark.textMuted)),
          const SizedBox(height: CobeSpacing.sm),
          Expanded(
            child: CobeSurface(
              child: ListView(
                children: const [
                  _DiffLine(prefix: '-', line: 'Text(\'Old chat header\')', color: Color(0xFF552727)),
                  _DiffLine(prefix: '+', line: 'Text(\'Chat\', style: CobeTitle)', color: Color(0xFF1F3A2E)),
                  _DiffLine(prefix: '+', line: 'Provider + model labels added per message', color: Color(0xFF1F3A2E)),
                  _DiffLine(prefix: '+', line: 'Streaming stop/regenerate controls', color: Color(0xFF1F3A2E)),
                  _DiffLine(prefix: ' ', line: 'Artifact list follows assistant response', color: Color(0xFF111114)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({required this.prefix, required this.line, required this.color});

  final String prefix;
  final String line;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: CobeSpacing.xs, horizontal: CobeSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 14, child: Text(prefix, style: const TextStyle(color: CobeTokens.dark.textMuted, fontSize: 12))),
          Expanded(child: Text(line, style: const TextStyle(fontSize: 12.5, color: CobeTokens.dark.textPrimary))),
        ],
      ),
    );
  }
}
