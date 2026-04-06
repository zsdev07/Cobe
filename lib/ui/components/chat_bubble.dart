import 'package:flutter/material.dart';

import '../../app/state/app_state.dart';
import '../theme/cobe_tokens.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    const t = CobeTokens.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: CobeSpacing.sm),
        padding: const EdgeInsets.all(CobeSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF18181B) : t.bgCard,
          borderRadius: CobeRadius.lg,
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.provider,
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                ),
                const SizedBox(width: CobeSpacing.xs),
                Container(width: 3, height: 3, decoration: BoxDecoration(color: t.textMuted, shape: BoxShape.circle)),
                const SizedBox(width: CobeSpacing.xs),
                Flexible(
                  child: Text(
                    message.model,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CobeSpacing.xs),
            SelectableText(
              message.text,
              style: TextStyle(fontSize: 13, color: t.textPrimary, height: 1.35),
            ),
            if (message.isStreaming)
              const Padding(
                padding: EdgeInsets.only(top: CobeSpacing.sm),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
