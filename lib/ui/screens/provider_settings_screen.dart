// provider_settings_screen.dart — Multi-model provider config hub
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../theme/cobe_theme.dart';
import '../widgets/glass_widgets.dart';

class ProviderSettingsScreen extends ConsumerStatefulWidget {
  const ProviderSettingsScreen({super.key});
  @override
  ConsumerState<ProviderSettingsScreen> createState() =>
      _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState
    extends ConsumerState<ProviderSettingsScreen> {
  static const _providers = [
    (0, 'Groq',   'Llama 3.3 70B / 8B',         Icons.bolt_rounded),
    (2, 'OpenAI', 'GPT-5 / GPT-4o',              Icons.auto_awesome_rounded),
    (3, 'Claude', 'Claude Sonnet 4.5 / 3.5',     Icons.psychology_outlined),
    (4, 'Gemini', 'Gemini 2.5 Flash / Pro',      Icons.diamond_outlined),
  ];

  final _controllers = <int, TextEditingController>{};
  bool _circular = true;

  @override
  void initState() {
    super.initState();
    for (final p in _providers) {
      _controllers[p.$1] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(providerConfigProvider);

    return Scaffold(
      backgroundColor: CobeColors.bg,
      appBar: AppBar(
        title: Text('Provider Settings'),
        backgroundColor: const Color(0xFF060810),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 16, color: CobeColors.textSub),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI Providers ────────────────────────────────────────────
          const _SectionHeader(title: 'AI Providers'),
          const SizedBox(height: 12),
          ..._providers.map((p) {
            final masked = config.keys[p.$1] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(p.$4, size: 16, color: CobeColors.pulse),
                        const SizedBox(width: 8),
                        Text(p.$2, style: CobeTextStyles.ui),
                        const Spacer(),
                        Text(p.$3, style: CobeTextStyles.uiSub),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ApiKeyField(
                            controller: _controllers[p.$1]!,
                            masked: masked,
                            hintText: 'Enter API key…',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SaveBtn(
                          onTap: () {
                            final key = _controllers[p.$1]!.text.trim();
                            if (key.isNotEmpty) {
                              ref
                                  .read(providerConfigProvider.notifier)
                                  .setKey(p.$1, key);
                              _controllers[p.$1]!.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          const _SectionHeader(title: 'Interface'),
          const SizedBox(height: 12),

          // ── Hover Menu Style ────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hover Menu Style', style: CobeTextStyles.ui),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RadioChip(
                      label: 'Circular',
                      selected: _circular,
                      onTap: () {
                        setState(() => _circular = true);
                        ref
                            .read(hoverMenuProvider.notifier)
                            .setStyle(true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _RadioChip(
                      label: 'Horizontal',
                      selected: !_circular,
                      onTap: () {
                        setState(() => _circular = false);
                        ref
                            .read(hoverMenuProvider.notifier)
                            .setStyle(false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const _SectionHeader(title: 'Security'),
          const SizedBox(height: 12),

          // ── Panic section ───────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: CobeColors.error),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panic Gesture', style: CobeTextStyles.ui),
                      SizedBox(height: 2),
                      Text(
                          'Double-tap logo or long-press to flush keys & lock DB',
                          style: CobeTextStyles.uiSub),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    triggerPanic(ref);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: CobeColors.error.withOpacity(0.5)),
                      color: CobeColors.error.withOpacity(0.1),
                    ),
                    child: Text('Trigger',
                        style: TextStyle(
                            color: CobeColors.error,
                            fontSize: 12,
                            fontFamily: 'JetBrainsMono')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: CobeTextStyles.label);
  }
}

class _ApiKeyField extends StatefulWidget {
  final TextEditingController controller;
  final String masked, hintText;
  const _ApiKeyField(
      {required this.controller,
      required this.masked,
      required this.hintText});
  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: CobeColors.glassDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CobeColors.glassBorder),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        style: CobeTextStyles.mono.copyWith(fontSize: 12),
        decoration: InputDecoration(
          hintText: widget.masked.isNotEmpty ? widget.masked : widget.hintText,
          hintStyle: CobeTextStyles.monoGhost.copyWith(fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 14, color: CobeColors.textSub),
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: CobeColors.pulse.withOpacity(0.2),
          border: Border.all(color: CobeColors.pulse.withOpacity(0.5)),
        ),
        child: const Center(
          child: Text('Save',
              style: TextStyle(
                  color: CobeColors.pulse,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono')),
        ),
      ),
    );
  }
}

class _RadioChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? CobeColors.pulse.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
              color: selected ? CobeColors.pulse : CobeColors.glassBorder),
        ),
        child: Text(label,
            style: CobeTextStyles.uiSub.copyWith(
                color: selected ? CobeColors.pulse : CobeColors.textSub)),
      ),
    );
  }
}
