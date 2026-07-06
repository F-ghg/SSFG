import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/verse_reference.dart';
import '../services/bible_repository.dart';
import '../services/reference_parser.dart';
import '../widgets/verse_result_sheet.dart';

/// Live camera view. The user points the camera at printed Bible verse
/// references and taps the shutter button to capture, run on-device OCR,
/// and show the matched verse text(s).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.bible});

  final BibleRepository bible;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _referenceParser = ReferenceParser();

  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      setState(() => _error = 'Could not start camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initFuture = _initCamera();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _captureAndScan() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final picture = await controller.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final references = _referenceParser.parse(recognized.text);
      if (!mounted) return;
      await _showResults(references);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showResults(List<VerseReference> references) async {
    if (references.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Bible reference found. Try again.')),
      );
      return;
    }
    final scanned = references
        .map(widget.bible.resolve)
        .whereType<ScannedVerse>()
        .toList();
    if (scanned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Found a reference, but couldn't look up the verse.")),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => VerseResultSheet(results: scanned),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan a verse reference')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              _ViewfinderOverlay(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: _ShutterButton(
                    isBusy: _isProcessing,
                    onTap: _captureAndScan,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 8),
          child: const Text(
            'Align the verse reference here',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black26, width: 4),
        ),
        child: isBusy
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : const Icon(Icons.camera_alt, size: 32, color: Colors.black87),
      ),
    );
  }
}
