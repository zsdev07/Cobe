import 'package:flutter/material.dart';

import '../../app/navigation/app_shell.dart';
import '../theme/cobe_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
      ..forward();
    Future<void>.delayed(const Duration(milliseconds: 920), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = CobeTokens.dark;
    return Scaffold(
      body: Container(
        color: t.bgBase,
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: CobeRadius.lg,
                color: t.bgPanel,
                border: Border.all(color: t.border),
                boxShadow: [BoxShadow(color: t.glow, blurRadius: 28, spreadRadius: 0.5)],
              ),
              child: Center(
                child: Text('C', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: t.textPrimary)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
