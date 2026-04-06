import 'package:flutter/material.dart';

import '../components/cobe_button.dart';
import '../components/cobe_surface.dart';
import '../theme/cobe_tokens.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController(
    text: """
void main() {
  print('Cobe editor ready');
}
""",
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CobeSpacing.md, CobeSpacing.md, CobeSpacing.md, 86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Editor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              CobeButton(label: 'Run', icon: Icons.play_arrow_rounded, onPressed: () {}),
            ],
          ),
          const SizedBox(height: CobeSpacing.sm),
          Text('lib/main.dart', style: TextStyle(fontSize: 11, color: CobeTokens.dark.textMuted)),
          const SizedBox(height: CobeSpacing.sm),
          Expanded(
            child: CobeSurface(
              padding: const EdgeInsets.all(CobeSpacing.sm),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontSize: 13, height: 1.3),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
