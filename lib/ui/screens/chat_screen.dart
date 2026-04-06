import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_state.dart';
import '../components/chat_bubble.dart';
import '../components/cobe_button.dart';
import '../components/cobe_surface.dart';
import '../components/file_tile.dart';
import '../theme/cobe_tokens.dart';

class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  Timer? _streamTimer;

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  void _simulateStream(ChatController controller) {
    _streamTimer?.cancel();
    const chunks = [
      'Generating mobile-first chat updates',
      'Generating mobile-first chat updates with',
      'Generating mobile-first chat updates with artifact extraction',
      'Generating mobile-first chat updates with artifact extraction and editor handoff.',
    ];
    var idx = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      controller.updateStreaming(chunks[idx]);
      idx += 1;
      if (idx >= chunks.length) {
        controller.stopStreaming();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final controller = ref.read(chatProvider.notifier);
    final draft = ref.watch(draftProvider);
    final artifacts = ref.watch(artifactFilesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(CobeSpacing.md, CobeSpacing.md, CobeSpacing.md, 86),
      child: Column(
        children: [
          const _Header(),
          const SizedBox(height: CobeSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  return ChatBubble(message: messages[index]);
                }
                return CobeSurface(
                  margin: const EdgeInsets.only(top: CobeSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generated Files', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: CobeSpacing.sm),
                      for (final file in artifacts) ...[
                        FileTile(file: file, onTap: () {}),
                        const SizedBox(height: CobeSpacing.xs),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: CobeSpacing.sm),
          Row(
            children: [
              Expanded(
                child: CobeButton(
                  label: 'Stop',
                  icon: Icons.stop_circle_outlined,
                  onPressed: () {
                    _streamTimer?.cancel();
                    controller.stopStreaming();
                  },
                  isGhost: true,
                ),
              ),
              const SizedBox(width: CobeSpacing.sm),
              Expanded(
                child: CobeButton(
                  label: 'Regenerate',
                  icon: Icons.replay_rounded,
                  onPressed: () {
                    controller.regenerate();
                    _simulateStream(controller);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: CobeSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: CobeTokens.dark.bgPanel,
              borderRadius: CobeRadius.md,
              border: Border.all(color: CobeTokens.dark.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (value) => ref.read(draftProvider.notifier).state = value,
                    controller: TextEditingController(text: draft)
                      ..selection = TextSelection.collapsed(offset: draft.length),
                    style: TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Type prompt…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(CobeSpacing.sm),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.sendUserMessage(draft);
                    _simulateStream(controller);
                  },
                  icon: Icon(Icons.arrow_upward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeProjectIdProvider);
    final project = ref.watch(projectsProvider).firstWhere((p) => p.id == activeId);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: CobeTokens.dark.textMuted)),
            ],
          ),
        ),
        CobeButton(label: 'Pinned', icon: Icons.push_pin_outlined, onPressed: () {}, isGhost: true),
      ],
    );
  }
}
