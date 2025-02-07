import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../widgets/crystal_lens_cropper.dart';
import '../services/cloudinary_service.dart';
import '../theme/gem_theme.dart';

class VideoCropPage extends StatefulWidget {
  final String videoUrl;
  final Function(String) onCropComplete;

  const VideoCropPage({
    Key? key,
    required this.videoUrl,
    required this.onCropComplete,
  }) : super(key: key);

  @override
  _VideoCropPageState createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  bool _isCropping = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final GlobalKey<CrystalLensCropperState> _cropperKey = GlobalKey<CrystalLensCropperState>();

  // Crystal theme colors
  static const Color deepCave = Color(0xFF1A1A1A);
  static const Color amethyst = Color(0xFF9966CC);
  static const Color emerald = Color(0xFF50C878);

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // Enable haptic feedback for the mystical experience
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleCrop(ui.Rect cropRect, ui.Size videoSize) async {
    setState(() => _isCropping = true);
    HapticFeedback.mediumImpact();

    try {
      final String croppedVideoUrl = await _cloudinaryService.cropVideo(
        videoUrl: widget.videoUrl,
        cropRect: cropRect,
        originalSize: videoSize,
      );

      // Success haptic feedback
      HapticFeedback.heavyImpact();
      
      // Call the completion handler with the new URL
      widget.onCropComplete(croppedVideoUrl);
      
      // Close the crop view
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error haptic feedback
      HapticFeedback.vibrate();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to crop video: $e',
              style: gemText.copyWith(color: Colors.white),
            ),
            backgroundColor: ruby.withOpacity(0.8),
          ),
        );
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Animated crystal background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _CrystalBackgroundPainter(
                  animation: _backgroundController,
                  amethyst: amethyst,
                  emerald: emerald,
                ),
                child: Container(),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Crystal-themed app bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _isCropping ? null : () => Navigator.pop(context),
                      ),
                      const Text(
                        'Crystal Lens',
                        style: TextStyle(
                          fontFamily: 'Audiowide',
                          color: Colors.white,
                          fontSize: 24,
                          shadows: [
                            Shadow(
                              color: amethyst,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: _isCropping ? null : () {
                          // Trigger the crop when check is pressed
                          _cropperKey.currentState?.triggerCrop();
                        },
                      ),
                    ],
                  ),
                ),

                // Crystal Lens Cropper
                Expanded(
                  child: Stack(
                    children: [
                      CrystalLensCropper(
                        key: _cropperKey,
                        videoUrl: widget.videoUrl,
                        onCropComplete: _handleCrop,
                      ),
                      if (_isCropping)
                        _buildCrystalLoadingOverlay(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalLoadingOverlay() {
    return Container(
      color: deepCave.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Crystal formation animation
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _CrystalLoadingPainter(
                  animation: _backgroundController,
                  amethyst: amethyst,
                  emerald: emerald,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crystallizing...',
              style: gemText.copyWith(
                color: Colors.white,
                fontSize: 18,
                shadows: [
                  Shadow(
                    color: amethyst,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
}

class _CrystalLoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color amethyst;
  final Color emerald;

  _CrystalLoadingPainter({
    required this.animation,
    required this.amethyst,
    required this.emerald,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw rotating crystals
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + animation.value * 2 * math.pi;
      final offset = Offset(
        center.dx + radius * 0.7 * math.cos(angle),
        center.dy + radius * 0.7 * math.sin(angle),
      );

      final path = Path();
      for (int j = 0; j < 3; j++) {
        final pointAngle = angle + (j * 2 * math.pi / 3);
        final point = Offset(
          offset.dx + radius * 0.2 * math.cos(pointAngle),
          offset.dy + radius * 0.2 * math.sin(pointAngle),
        );
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          offset - Offset(radius * 0.2, 0),
          offset + Offset(radius * 0.2, 0),
          [
            amethyst.withOpacity(0.8 + 0.2 * math.sin(animation.value * math.pi)),
            emerald.withOpacity(0.8 - 0.2 * math.sin(animation.value * math.pi)),
          ],
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrystalBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color amethyst;
  final Color emerald;

  _CrystalBackgroundPainter({
    required this.animation,
    required this.amethyst,
    required this.emerald,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          amethyst.withOpacity(0.1 + 0.05 * animation.value),
          emerald.withOpacity(0.1 - 0.05 * animation.value),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    // Draw animated crystal patterns
    final path = Path();
    final numberOfCrystals = 5;
    final crystalSize = size.width / numberOfCrystals;

    for (var i = 0; i < numberOfCrystals; i++) {
      for (var j = 0; j < numberOfCrystals; j++) {
        final crystalPath = Path();
        final center = Offset(
          i * crystalSize + crystalSize / 2,
          j * crystalSize + crystalSize / 2,
        );
        
        // Create crystal shape
        final points = <Offset>[];
        final sides = 6;
        for (var k = 0; k < sides; k++) {
          final angle = (k * 2 * math.pi) / sides + animation.value;
          points.add(Offset(
            center.dx + math.cos(angle) * crystalSize / 3,
            center.dy + math.sin(angle) * crystalSize / 3,
          ));
        }
        
        crystalPath.addPolygon(points, true);
        path.addPath(crystalPath, Offset.zero);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 