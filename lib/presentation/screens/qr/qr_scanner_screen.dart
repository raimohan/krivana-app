import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/glass/glass_container.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _scannerController;
  String? _scannedValue;
  final bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedValue != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      HapticFeedback.heavyImpact();
      setState(() => _scannedValue = barcode!.rawValue!);
      _showResultSheet();
    }
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      useSafeArea: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scanned Result',
                    style: AppTextStyles.heading2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(12),
                    tintOpacity: isDark ? 0.06 : 0.12,
                    child: Text(
                      _scannedValue ?? '',
                      style: AppTextStyles.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            foregroundColor: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _scannedValue ?? ''));
                            Navigator.pop(context);
                          },
                          child: Text('Copy', style: AppTextStyles.buttonLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            context.pop(_scannedValue);
                          },
                          child: Text('Use this URL', style: AppTextStyles.buttonLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // Allow scanning again after dismissal
      setState(() => _scannedValue = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.65;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          if (_hasPermission)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onDetect,
              errorBuilder: (_, error) {
                return Center(
                  child: Text(
                    'Camera permission denied',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                );
              },
            ),

          // Overlay
          CustomPaint(
            size: size,
            painter: _ScanOverlayPainter(
              scanRect: Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2),
                width: scanSize,
                height: scanSize,
              ),
            ),
          ),

          // Animated corner brackets
          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: CustomPaint(
                painter: _CornerPainter(),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: GlassContainer(
                borderRadius: 50,
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Rect scanRect;

  _ScanOverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    const r = 12.0;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );

    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      paint,
    );

    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
      paint,
    );

    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(
            size.width, size.height, size.width, size.height - r)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
