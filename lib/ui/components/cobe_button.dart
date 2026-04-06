import 'package:flutter/material.dart';

import '../theme/cobe_tokens.dart';

class CobeButton extends StatelessWidget {
  const CobeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isGhost = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    return InkWell(
      borderRadius: CobeRadius.md,
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CobeSpacing.md, vertical: CobeSpacing.sm),
        decoration: BoxDecoration(
          color: isGhost ? t.bgPanel : t.accent,
          borderRadius: CobeRadius.md,
          border: Border.all(color: isGhost ? t.border : t.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isGhost ? t.textPrimary : t.bgBase),
              const SizedBox(width: CobeSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: isGhost ? t.textPrimary : t.bgBase,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
