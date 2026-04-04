// main.dart — Cobe entry point
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'core/ffi/ffi_bridge.dart';
import 'ui/screens/editor_screen.dart';
import 'ui/theme/cobe_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050709),
  ));

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  ffi.load();

  final dir = await getApplicationDocumentsDirectory();
  final dbPath = '${dir.path}/cobe.db';
  ffi.init(dbPath, 'cobe_master_v1');

  if (Platform.isAndroid) {
    ffi.scanProject(dir.path);
  }

  runApp(const ProviderScope(child: CobeApp()));
}

class CobeApp extends StatelessWidget {
  const CobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobe',
      debugShowCheckedModeBanner: false,
      theme: cobeTheme(),
      home: const EditorScreen(),
    );
  }
}
