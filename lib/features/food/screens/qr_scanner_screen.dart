import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/widgets/qr_manual_entry_dialog.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _handled = false;
  bool _cooldown = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    try {
      if (state == AppLifecycleState.resumed) {
        _controller.start().catchError((_) {});
      } else {
        _controller.stop().catchError((_) {});
      }
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || _cooldown) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;

      final location = matchScannedPayload(raw);
      if (location != null) {
        _handled = true;
        if (mounted) {
          Navigator.of(context).pop(location);
        }
        return;
      } else {
        _cooldown = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location not recognized. Please scan a valid delivery QR.',
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _cooldown = false;
            });
          } else {
            _cooldown = false;
          }
        });
        return;
      }
    }
  }

  Future<void> _openManualEntry() async {
    final location = await showDialog<DeliveryLocation>(
      context: context,
      builder: (_) => const QrManualEntryDialog(),
    );
    if (location != null && mounted) {
      _handled = true;
      Navigator.of(context).pop(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _openManualEntry,
            child: const Text(
              'Enter code manually',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Toggle Flashlight',
              onPressed: () async {
                try {
                  await _controller.toggleTorch();
                } catch (_) {}
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanSize = (constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight) *
              0.65;

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  final String message;
                  switch (error.errorCode) {
                    case MobileScannerErrorCode.permissionDenied:
                      message =
                          'Camera permission was denied. Please grant permission or enter the code manually.';
                      break;
                    case MobileScannerErrorCode.unsupported:
                      message =
                          'Camera scanning is not supported on this device. Please enter the code manually.';
                      break;
                    default:
                      message =
                          'Camera is unavailable. Please enter the code manually.';
                      break;
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            size: 48,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _openManualEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Enter code manually'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, state, child) {
                  if (state.error != null) {
                    return const SizedBox.shrink();
                  }
                  return child!;
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _ScannerOverlayPainter(
                        scanSize: scanSize,
                        borderRadius: 16.0,
                      ),
                    ),
                    Positioned(
                      top: (constraints.maxHeight + scanSize) / 2 + 20,
                      left: 24,
                      right: 24,
                      child: const Text(
                        'Point the camera at a delivery location QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanSize;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.scanSize,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );

    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanRect,
        Radius.circular(borderRadius),
      ));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutOutPath,
    );

    final overlayPaint = Paint()..color = const Color(0x99000000);
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanRect,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanSize != scanSize ||
      oldDelegate.borderRadius != borderRadius;
}
