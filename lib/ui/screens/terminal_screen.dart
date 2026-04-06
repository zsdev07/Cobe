// terminal_screen.dart — PTY-backed integrated terminal (opt-in)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/cobe_theme.dart';
import '../widgets/glass_widgets.dart';

// Terminal enabled toggle
final terminalEnabledProvider = StateProvider<bool>((ref) => false);

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});
  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  Process? _process;
  final _output = <_TermLine>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _running = false;
  StreamSubscription? _stdoutSub, _stderrSub;

  @override
  void initState() {
    super.initState();
    _startShell();
  }

  Future<void> _startShell() async {
    try {
      _process = await Process.start(
        '/system/bin/sh',
        [],
        environment: {'TERM': 'xterm-256color', 'HOME': '/data/data/zx.offical.cobe'},
        runInShell: false,
      );
      setState(() => _running = true);

      _stdoutSub = _process!.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) => _appendOutput(data, false));

      _stderrSub = _process!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((data) => _appendOutput(data, true));

      _process!.exitCode.then((_) {
        if (mounted) setState(() => _running = false);
      });
    } catch (e) {
      _appendOutput('Failed to start shell: $e\n', true);
    }
  }

  void _appendOutput(String text, bool isError) {
    setState(() {
      for (final line in text.split('\n')) {
        if (line.isNotEmpty) _output.add(_TermLine(line, isError));
      }
      // Keep last 500 lines
      if (_output.length > 500) _output.removeRange(0, _output.length - 500);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _sendInput(String cmd) {
    if (_process == null || !_running) return;
    _process!.stdin.writeln(cmd);
    _appendOutput('\$ $cmd\n', false);
    _inputCtrl.clear();
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(terminalEnabledProvider);
    if (!enabled) return const _TerminalDisabled();

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: CobeColors.divider)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded,
                    size: 14, color: CobeColors.accent),
                const SizedBox(width: 8),
                Text('Terminal', style: CobeTextStyles.uiSub),
                const Spacer(),
                _dot(CobeColors.error),
                const SizedBox(width: 4),
                _dot(CobeColors.warning),
                const SizedBox(width: 4),
                _dot(CobeColors.success),
              ],
            ),
          ),
          // Output
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(8),
              itemCount: _output.length,
              itemBuilder: (_, i) {
                final line = _output[i];
                return Text(
                  line.text,
                  style: CobeTextStyles.mono.copyWith(
                    fontSize: 12,
                    color: line.isError
                        ? CobeColors.error.withOpacity(0.85)
                        : CobeColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          // Input
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: CobeColors.divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Text('\$ ', style: CobeTextStyles.mono.copyWith(
                    color: CobeColors.accent, fontSize: 12)),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: CobeTextStyles.mono.copyWith(fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'enter command…',
                      hintStyle: TextStyle(
                          color: CobeColors.textSub,
                          fontSize: 12,
                          fontFamily: 'JetBrainsMono'),
                    ),
                    onSubmitted: _sendInput,
                    enabled: _running,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _TermLine {
  final String text;
  final bool isError;
  _TermLine(this.text, this.isError);
}

class _TerminalDisabled extends ConsumerWidget {
  const _TerminalDisabled();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_rounded, size: 28, color: CobeColors.textSub),
          const SizedBox(height: 10),
          Text('Terminal is disabled', style: CobeTextStyles.ui),
          const SizedBox(height: 4),
          Text('Enable in Provider Settings → Interface',
              style: CobeTextStyles.uiSub),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                ref.read(terminalEnabledProvider.notifier).state = true,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: CobeColors.pulse.withOpacity(0.15),
                border: Border.all(
                    color: CobeColors.pulse.withOpacity(0.4)),
              ),
              child: Text('Enable Terminal',
                  style: TextStyle(
                      color: CobeColors.pulse,
                      fontSize: 13,
                      fontFamily: 'JetBrainsMono')),
            ),
          ),
        ],
      ),
    );
  }
}
