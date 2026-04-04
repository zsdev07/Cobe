// editor_screen.dart — Cobe main editor: re_editor + ghost text + panic gesture
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import '../../core/providers/providers.dart';
import '../theme/cobe_theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/hover_menu.dart';
import '../widgets/artifacts_panel.dart';
import 'provider_settings_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late CodeLineEditingController _codeCtrl;
  Timer? _ghostTimer;
  int _logoPressCount = 0;
  Timer? _logoResetTimer;

  @override
  void initState() {
    super.initState();
    _codeCtrl = CodeLineEditingController.fromText('// Welcome to Cobe\n');
    _codeCtrl.addListener(_onEdit);
  }

  void _onEdit() {
    ref.read(fileEditorProvider.notifier).edit(_codeCtrl.text);
    _ghostTimer?.cancel();
    _ghostTimer = Timer(const Duration(milliseconds: 800), () {
      final line = _currentLine();
      if (line.trim().isNotEmpty) {
        ref.read(aiProvider.notifier).ghostSuggest(line);
      }
    });
  }

  String _currentLine() {
    try {
      final sel = _codeCtrl.selection;
      final text = _codeCtrl.text;
      final start = text.lastIndexOf('\n', sel.start - 1) + 1;
      final end = text.indexOf('\n', sel.start);
      return text.substring(start, end < 0 ? text.length : end);
    } catch (_) { return ''; }
  }

  void _onLogoPressCount() {
    _logoPressCount++;
    _logoResetTimer?.cancel();
    _logoResetTimer = Timer(const Duration(milliseconds: 500), () {
      _logoPressCount = 0;
    });
    if (_logoPressCount >= 2) {
      _logoPressCount = 0;
      triggerPanic(ref);
    }
  }

  @override
  void dispose() {
    _codeCtrl.removeListener(_onEdit);
    _codeCtrl.dispose();
    _ghostTimer?.cancel();
    _logoResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState  = ref.watch(fileEditorProvider);
    final aiState      = ref.watch(aiProvider);
    final indexing     = ref.watch(indexingProvider);
    final panic        = ref.watch(panicProvider);
    final statusMsg    = ref.watch(engineStatusProvider).value ?? 'Ready';

    return Scaffold(
      backgroundColor: CobeColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────────
              _TopBar(
                filePath: editorState.path,
                dirty: editorState.dirty,
                onLogoTap: _onLogoPressCount,
                onLogoLongPress: () => triggerPanic(ref),
                onSave: () => ref.read(fileEditorProvider.notifier).save(),
                onSettings: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ProviderSettingsScreen())),
              ),
              // ── Editor + Artifacts Row ────────────────────────────────
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: PulseGlowBorder(
                        active: aiState.status == AiStatus.thinking,
                        child: _CodeEditor(
                          ctrl: _codeCtrl,
                          ghostText: aiState.ghostText,
                        ),
                      ),
                    ),
                    // Artifacts side panel
                    SizedBox(
                      width: 28,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const ArtifactsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
              // ── AI Prompt Bar ─────────────────────────────────────────
              _AiBar(aiState: aiState),
              // ── Status Bar ────────────────────────────────────────────
              CobeStatusBar(
                message: indexing.active
                    ? 'Indexing: ${indexing.currentFile}'
                    : statusMsg,
                indexing: indexing.active,
              ),
            ],
          ),
          // ── Hover Menu ────────────────────────────────────────────────
          Positioned.fill(child: Stack(children: const [HoverMenu()])),
          // ── Frost Overlay (Panic) ─────────────────────────────────────
          if (panic)
            Positioned.fill(child: FrostOverlay(active: panic)),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String filePath;
  final bool dirty;
  final VoidCallback onLogoTap, onLogoLongPress, onSave, onSettings;

  const _TopBar({
    required this.filePath,
    required this.dirty,
    required this.onLogoTap,
    required this.onLogoLongPress,
    required this.onSave,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFF060810),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Logo — panic trigger
          GestureDetector(
            onTap: onLogoTap,
            onLongPress: onLogoLongPress,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [CobeColors.pulse, CobeColors.accent, CobeColors.pulse],
                ),
              ),
              child: const Center(
                child: Text('C',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // File path + dirty dot
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    filePath.isEmpty ? 'untitled' : filePath.split('/').last,
                    style: CobeTextStyles.ui.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                DirtyDot(visible: dirty),
              ],
            ),
          ),
          // Save + Settings
          IconButton(
            icon: const Icon(Icons.save_outlined,
                size: 18, color: CobeColors.textSub),
            onPressed: onSave,
            tooltip: 'Save (Ctrl+S)',
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                size: 18, color: CobeColors.textSub),
            onPressed: onSettings,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Code Editor ───────────────────────────────────────────────────────────
class _CodeEditor extends StatelessWidget {
  final CodeLineEditingController ctrl;
  final String ghostText;

  const _CodeEditor({required this.ctrl, required this.ghostText});

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      controller: ctrl,
      style: CodeEditorStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 13,
        textColor: CobeColors.textPrimary,
        backgroundColor: CobeColors.bg,
        selectionColor: CobeColors.pulse.withOpacity(0.3),
        cursorColor: CobeColors.accent,
        gutterStyle: const CodeGutterStyle(
          backgroundColor: Color(0xFF060810),
          textColor: CobeColors.textSub,
          width: 48,
        ),
      ),
      indicatorBuilder: (_, controller, chunkController, notifier) =>
          Row(children: [
        DefaultCodeLineNumber(
            controller: controller, notifier: notifier),
        DefaultCodeChunkIndicator(
            width: 16,
            controller: chunkController,
            notifier: notifier),
      ]),
      scrollbarBuilder: (_, child, details) => Scrollbar(
        thumbVisibility: true,
        thickness: 4,
        child: child,
      ),
    );
  }
}

// ── AI Prompt Bar ─────────────────────────────────────────────────────────
class _AiBar extends ConsumerStatefulWidget {
  final AiState aiState;
  const _AiBar({required this.aiState});
  @override
  ConsumerState<_AiBar> createState() => _AiBarState();
}

class _AiBarState extends ConsumerState<_AiBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    ref.read(aiProvider.notifier).ask(prompt: _ctrl.text.trim());
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final thinking = widget.aiState.status == AiStatus.thinking;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080A0E),
        border: Border(top: BorderSide(color: CobeColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: CobeTextStyles.mono.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: thinking ? 'AI is thinking…' : 'Ask Cobe anything…',
                hintStyle: CobeTextStyles.monoGhost,
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
              enabled: !thinking,
            ),
          ),
          if (thinking)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: CobeColors.pulse),
            )
          else
            GestureDetector(
              onTap: _submit,
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 18, color: CobeColors.pulse),
            ),
        ],
      ),
    );
  }
}
