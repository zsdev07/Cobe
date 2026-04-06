import 'package:flutter/material.dart';

import '../../ui/components/floating_taskbar.dart';
import '../../ui/screens/chat_screen.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/diff_screen.dart';
import '../../ui/screens/editor_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/theme/cobe_tokens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _activeIndex = 2;

  late final List<Widget> _pages = const [
    SettingsScreen(),
    ChatHistoryScreen(),
    DashboardScreen(),
    DiffScreen(),
    EditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: CobeTokens.dark.bgBase,
                child: IndexedStack(index: _activeIndex, children: _pages),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: FloatingTaskbar(
                activeIndex: _activeIndex,
                onTap: (index) => setState(() => _activeIndex = index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
