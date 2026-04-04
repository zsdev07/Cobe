import 'dart:async';
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
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  String status = 'Starting Cobe...';
  bool failed = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_boot);
  }

  Future<void> _boot() async {
    try {
      setState(() => status = 'Loading native engine...');
      ffi.load();

      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/cobe.db';

      setState(() => status = 'Initializing database...');
      final ok = ffi.init(dbPath, 'cobe_master_v1');

      if (!ok) {
        throw Exception('ffi.init() returned false');
      }

      // Delay scan until first UI frame is already shown
      if (Platform.isAndroid) {
        unawaited(Future<void>.delayed(const Duration(milliseconds: 500), () async {
          try {
            ffi.scanProject(dir.path);
          } catch (_) {}
        }));
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        failed = true;
        status = 'Startup failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050709),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (failed) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      failed = false;
                      status = 'Retrying...';
                    });
                    _boot();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
