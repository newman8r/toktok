import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../widgets/crystal_lens_cropper.dart';

class VideoCropPage extends StatefulWidget {
  final String videoUrl;

  const VideoCropPage({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _VideoCropPageState createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  bool _isCropping = false;

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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: _isCropping ? null : _onCropComplete,
                      ),
                    ],
                  ),
                ),

                // Crystal Lens Cropper
                Expanded(
                  child: CrystalLensCropper(
                    videoUrl: widget.videoUrl,
                    onCropComplete: (rect) {
                      // Handle crop completion
                      setState(() => _isCropping = true);
                      // Simulate processing with a mystical delay
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() => _isCropping = false);
                      });
                    },
                  ),
                ),

                // Crystal control panel
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: deepCave.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: amethyst.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Aspect ratio selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAspectRatioButton('1:1', Icons.crop_square),
                          _buildAspectRatioButton('4:5', Icons.crop_portrait),
                          _buildAspectRatioButton('16:9', Icons.crop_landscape),
                          _buildAspectRatioButton('Free', Icons.crop_free),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Processing indicator
                      if (_isCropping)
                        const LinearProgressIndicator(
                          backgroundColor: deepCave,
                          valueColor: AlwaysStoppedAnimation<Color>(amethyst),
                        ),
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

  Widget _buildAspectRatioButton(String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                amethyst.withOpacity(0.8),
                emerald.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: amethyst.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: () {
              // Handle aspect ratio change
              HapticFeedback.selectionClick();
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _onCropComplete() {
    // Handle crop completion
    HapticFeedback.mediumImpact();
    // TODO: Implement crop completion
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
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