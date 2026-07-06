import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/scanner_screen.dart';
import 'services/bible_repository.dart';

void main() {
  runApp(const BibleVerseScannerApp());
}

class BibleVerseScannerApp extends StatelessWidget {
  const BibleVerseScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Verse Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StartupPage(),
    );
  }
}

/// Requests camera permission and loads the bundled Bible data before
/// handing off to the scanner screen.
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  late final Future<_StartupResult> _startup = _prepare();

  Future<_StartupResult> _prepare() async {
    final status = await Permission.camera.request();
    final bible = await BibleRepository.load();
    return _StartupResult(cameraGranted: status.isGranted, bible: bible);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupResult>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Failed to start: ${snapshot.error}')),
          );
        }
        final result = snapshot.data!;
        if (!result.cameraGranted) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Camera access is required to scan verse references.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open settings'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ScannerScreen(bible: result.bible);
      },
    );
  }
}

class _StartupResult {
  final bool cameraGranted;
  final BibleRepository bible;

  _StartupResult({required this.cameraGranted, required this.bible});
}
