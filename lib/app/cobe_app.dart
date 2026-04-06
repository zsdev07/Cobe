import 'package:flutter/material.dart';

import '../ui/screens/splash_screen.dart';
import '../ui/theme/cobe_theme.dart';

class CobeApp extends StatelessWidget {
  const CobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobe',
      debugShowCheckedModeBanner: false,
      theme: buildCobeTheme(),
      home: const SplashScreen(),
    );
  }
}
