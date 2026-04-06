// artifacts_panel.dart — Sliding side-panel: diff view + action buttons
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../theme/cobe_theme.dart';
import 'glass_widgets.dart';

class ArtifactsPanel extends ConsumerStatefulWidget {
  const ArtifactsPanel({super.key});
  @override
  ConsumerState<ArtifactsPanel> createState() => _ArtifactsPanelState();
}

class _ArtifactsPanelState extends ConsumerState<ArtifactsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  void toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final artifacts = ref.watch(artifactsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Toggle tab
        GestureDetector(
          onTap: toggle,
          child: Container(
            width: 28,
            height: 80,
            decoration: BoxDecoration(
              color: CobeColors.glass,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              border: Border.all(color: CobeColors.glassBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_open ? Icons.chevron_right : Icons.chevron_left,
                    size: 16, color: CobeColors.textSub),
                if (artifacts.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                        color: CobeColors.pulse, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${artifacts.length}',
                          style: TextStyle(
                              fontSize: 8, color: Colors.white,
                              fontFamily: 'JetBrainsMono')),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Panel
        SlideTransition(
          position: _slide,
          child: SizedBox(
            width: 340,
            child: GlassPanel(
              radius: const BorderRadius.horizontal(left: Radius.circular(16)),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelHeader(artifactCount: artifacts.length),
                  Expanded(
                    child: artifacts.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: artifacts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: CobeColors.divider, height: 16),
                            itemBuilder: (_, i) =>
                                _ArtifactCard(index: i, artifact: artifacts[i]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final int artifactCount;
  const _PanelHeader({required this.artifactCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CobeColors.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded,
              size: 16, color: CobeColors.pulse),
          const SizedBox(width: 8),
          Text('Artifacts ($artifactCount)', style: CobeTextStyles.ui),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_rounded, size: 32, color: CobeColors.textSub),
          SizedBox(height: 8),
          Text('No artifacts yet', style: CobeTextStyles.uiSub),
        ],
      ),
    );
  }
}

class _ArtifactCard extends ConsumerStatefulWidget {
  final int index;
  final DiffArtifact artifact;
  const _ArtifactCard({required this.index, required this.artifact});
  @override
  ConsumerState<_ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends ConsumerState<_ArtifactCard> {
  bool _showDiff = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.artifact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        GestureDetector(
          onTap: () => setState(() => _showDiff = !_showDiff),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 14, color: CobeColors.accent),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(a.fileName,
                      style: CobeTextStyles.ui.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
              Icon(_showDiff ? Icons.expand_less : Icons.expand_more,
                  size: 14, color: CobeColors.textSub),
            ],
          ),
        ),
        // Diff view
        if (_showDiff) ...[
          const SizedBox(height: 8),
          _DiffView(original: a.original, proposed: a.proposed),
          const SizedBox(height: 8),
        ],
        // Action buttons
        Row(
          children: [
            _ActionBtn(
              label: 'Apply',
              color: CobeColors.success,
              onTap: () =>
                  ref.read(artifactsProvider.notifier).apply(widget.index),
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              label: 'Discard',
              color: CobeColors.error,
              onTap: () =>
                  ref.read(artifactsProvider.notifier).remove(widget.index),
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              label: 'Refine',
              color: CobeColors.warning,
              onTap: () {
                ref.read(aiProvider.notifier).ask(
                    prompt: 'Refine this change for ${a.fileName}:\n${a.proposed}',
                    provider: 0);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DiffView extends StatelessWidget {
  final String original, proposed;
  const _DiffView({required this.original, required this.proposed});

  List<(String, bool?)> _computeDiff() {
    final oldLines = original.split('\n');
    final newLines = proposed.split('\n');
    final result = <(String, bool?)>[];
    final maxL = newLines.length > oldLines.length ? newLines.length : oldLines.length;
    for (int i = 0; i < maxL; i++) {
      if (i >= newLines.length) {
        result.add(('- ${oldLines[i]}', false));
      } else if (i >= oldLines.length) {
        result.add(('+ ${newLines[i]}', true));
      } else if (oldLines[i] != newLines[i]) {
        result.add(('- ${oldLines[i]}', false));
        result.add(('+ ${newLines[i]}', true));
      } else {
        result.add(('  ${oldLines[i]}', null));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _computeDiff();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CobeColors.glassBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((l) {
            Color lineColor = CobeColors.textSub;
            if (l.$2 == true)  lineColor = CobeColors.success.withOpacity(0.8);
            if (l.$2 == false) lineColor = CobeColors.error.withOpacity(0.8);
            return Container(
              color: l.$2 == true
                  ? CobeColors.success.withOpacity(0.06)
                  : l.$2 == false
                      ? CobeColors.error.withOpacity(0.06)
                      : Colors.transparent,
              child: Text(l.$1,
                  style: CobeTextStyles.mono.copyWith(
                      color: lineColor, fontSize: 11)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
          color: color.withOpacity(0.1),
        ),
        child: Text(label,
            style: CobeTextStyles.uiSub.copyWith(color: color, fontSize: 11)),
      ),
    );
  }
}
