import 'package:flutter/material.dart';

import '../../app/state/app_state.dart';
import '../theme/cobe_tokens.dart';

class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.file, this.onTap});

  final ArtifactFile file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    final statusColor = switch (file.status) {
      'created' => const Color(0xFF58D18C),
      'updated' => const Color(0xFF86A7FF),
      _ => t.textMuted,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: CobeRadius.md,
      child: Container(
        padding: const EdgeInsets.all(CobeSpacing.sm),
        decoration: BoxDecoration(
          color: t.bgPanel,
          borderRadius: CobeRadius.md,
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 18, color: t.textPrimary),
            const SizedBox(width: CobeSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: t.textPrimary),
                  ),
                  Text(
                    '${file.lines} lines',
                    style: TextStyle(fontSize: 11, color: t.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              file.status,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
