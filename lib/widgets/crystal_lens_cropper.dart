import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class CrystalLensCropper extends StatefulWidget {
  final String videoUrl;
  final Function(Rect) onCropComplete;
  final double aspectRatio;

  const CrystalLensCropper({
    Key? key,
    required this.videoUrl,
    required this.onCropComplete,
    this.aspectRatio = 9 / 16,
  }) : super(key: key);

  @override
  _CrystalLensCropperState createState() => _CrystalLensCropperState();
}

class _CrystalLensCropperState extends State<CrystalLensCropper> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _crystalController;
  late Rect _cropRect;
  late Size _videoSize;
  
  // Crystal theme colors
  static const Color amethyst = Color(0xFF9966CC);
  static const Color sapphire = Color(0xFF0F52BA);
  static const Color crystalGlow = Color(0x1FFFFFFF);
  
  // Handle positions for the 8 crop handles
  final List<Offset> _handlePositions = [];
  int? _activeHandleIndex;
  
  // Panning
  Offset? _lastPanPosition;
  bool _isPanning = false;

  // Handle interaction constants
  static const double _handleHitArea = 40.0; // Larger hit area for handles
  static const double _edgeHitArea = 20.0; // Area around edges for resizing

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _crystalController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    
    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.play();
      
      setState(() {
        _videoSize = _videoController.value.size;
        // Initialize crop rect to slightly smaller than video size
        _cropRect = Rect.fromCenter(
          center: Offset(_videoSize.width / 2, _videoSize.height / 2),
          width: _videoSize.width * 0.9, // Start slightly smaller
          height: _videoSize.height * 0.9,
        );
        _updateHandlePositions();
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _updateHandlePositions() {
    _handlePositions.clear();
    // Corners
    _handlePositions.addAll([
      _cropRect.topLeft,
      _cropRect.topRight,
      _cropRect.bottomLeft,
      _cropRect.bottomRight,
    ]);
    // Edges
    _handlePositions.addAll([
      Offset(_cropRect.left + _cropRect.width / 2, _cropRect.top),
      Offset(_cropRect.right, _cropRect.top + _cropRect.height / 2),
      Offset(_cropRect.left + _cropRect.width / 2, _cropRect.bottom),
      Offset(_cropRect.left, _cropRect.top + _cropRect.height / 2),
    ]);
  }

  bool _isNearHandle(Offset touchPosition, Offset handlePosition) {
    return (touchPosition - handlePosition).distance < _handleHitArea;
  }

  bool _isNearEdge(Offset position) {
    final double distanceFromLeft = (position.dx - _cropRect.left).abs();
    final double distanceFromRight = (position.dx - _cropRect.right).abs();
    final double distanceFromTop = (position.dy - _cropRect.top).abs();
    final double distanceFromBottom = (position.dy - _cropRect.bottom).abs();
    
    return distanceFromLeft < _edgeHitArea ||
           distanceFromRight < _edgeHitArea ||
           distanceFromTop < _edgeHitArea ||
           distanceFromBottom < _edgeHitArea;
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the scaling factor to fit the video in the screen
        final double scale = math.min(
          constraints.maxWidth / _videoSize.width,
          constraints.maxHeight / _videoSize.height,
        );

        final Size scaledVideoSize = Size(
          _videoSize.width * scale,
          _videoSize.height * scale,
        );

        return Stack(
          children: [
            // Video preview
            Center(
              child: SizedBox(
                width: scaledVideoSize.width,
                height: scaledVideoSize.height,
                child: VideoPlayer(_videoController),
              ),
            ),
            
            // Crystal crop overlay
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);
                  
                  // Check if we're touching a handle first
                  for (int i = 0; i < _handlePositions.length; i++) {
                    if (_isNearHandle(localPosition, _handlePositions[i])) {
                      setState(() {
                        _activeHandleIndex = i;
                        _isPanning = false;
                      });
                      return;
                    }
                  }
                  
                  // If not near a handle or edge, start panning
                  if (!_isNearEdge(localPosition)) {
                    setState(() {
                      _lastPanPosition = localPosition;
                      _isPanning = true;
                    });
                  }
                },
                onPanUpdate: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);
                  
                  setState(() {
                    if (_isPanning) {
                      // Calculate new position
                      final Offset delta = localPosition - _lastPanPosition!;
                      Rect newRect = _cropRect.translate(delta.dx, delta.dy);
                      
                      // Constrain to video bounds
                      if (newRect.left < 0) {
                        newRect = newRect.translate(-newRect.left, 0);
                      }
                      if (newRect.top < 0) {
                        newRect = newRect.translate(0, -newRect.top);
                      }
                      if (newRect.right > _videoSize.width) {
                        newRect = newRect.translate(_videoSize.width - newRect.right, 0);
                      }
                      if (newRect.bottom > _videoSize.height) {
                        newRect = newRect.translate(0, _videoSize.height - newRect.bottom);
                      }
                      
                      _cropRect = newRect;
                      _lastPanPosition = localPosition;
                    } else if (_activeHandleIndex != null) {
                      _updateCropRect(localPosition);
                    }
                    _updateHandlePositions();
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _activeHandleIndex = null;
                    _isPanning = false;
                    _lastPanPosition = null;
                  });
                  widget.onCropComplete(_cropRect);
                },
                child: CustomPaint(
                  painter: _CrystalOverlayPainter(
                    cropRect: _cropRect,
                    handlePositions: _handlePositions,
                    crystalAnimation: _crystalController,
                    amethyst: amethyst,
                    sapphire: sapphire,
                    crystalGlow: crystalGlow,
                    videoSize: scaledVideoSize,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateCropRect(Offset newPosition) {
    // Calculate the maximum allowed rect based on video size
    final maxRect = Rect.fromLTWH(0, 0, _videoSize.width, _videoSize.height);
    
    Rect newRect = _cropRect;
    
    switch (_activeHandleIndex) {
      case 0: // Top-left
        newRect = Rect.fromPoints(newPosition, _cropRect.bottomRight);
        break;
      case 1: // Top-right
        newRect = Rect.fromPoints(_cropRect.bottomLeft, newPosition);
        break;
      case 2: // Bottom-left
        newRect = Rect.fromPoints(_cropRect.topRight, newPosition);
        break;
      case 3: // Bottom-right
        newRect = Rect.fromPoints(_cropRect.topLeft, newPosition);
        break;
      case 4: // Top center
        newRect = Rect.fromLTRB(
          _cropRect.left,
          newPosition.dy,
          _cropRect.right,
          _cropRect.bottom,
        );
        break;
      case 5: // Right center
        newRect = Rect.fromLTRB(
          _cropRect.left,
          _cropRect.top,
          newPosition.dx,
          _cropRect.bottom,
        );
        break;
      case 6: // Bottom center
        newRect = Rect.fromLTRB(
          _cropRect.left,
          _cropRect.top,
          _cropRect.right,
          newPosition.dy,
        );
        break;
      case 7: // Left center
        newRect = Rect.fromLTRB(
          newPosition.dx,
          _cropRect.top,
          _cropRect.right,
          _cropRect.bottom,
        );
        break;
    }
    
    // Ensure minimum size (e.g., 50x50 pixels)
    const minSize = 50.0;
    if (newRect.width < minSize || newRect.height < minSize) {
      return;
    }
    
    // Constrain to video bounds
    if (maxRect.contains(newRect.topLeft) && 
        maxRect.contains(newRect.bottomRight)) {
      _cropRect = newRect;
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _crystalController.dispose();
    super.dispose();
  }
}

class _CrystalOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final List<Offset> handlePositions;
  final Animation<double> crystalAnimation;
  final Color amethyst;
  final Color sapphire;
  final Color crystalGlow;
  final Size videoSize;

  // Visual constants
  static const double _handleVisualSize = 12.0; // Visual size of handles

  _CrystalOverlayPainter({
    required this.cropRect,
    required this.handlePositions,
    required this.crystalAnimation,
    required this.amethyst,
    required this.sapphire,
    required this.crystalGlow,
    required this.videoSize,
  }) : super(repaint: crystalAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // Center the overlay relative to the video size
    final Offset videoOffset = Offset(
      (size.width - videoSize.width) / 2,
      (size.height - videoSize.height) / 2,
    );
    
    // Draw semi-transparent overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    // Create path for overlay with crystal-like cutout
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(
        videoOffset.dx,
        videoOffset.dy,
        videoSize.width,
        videoSize.height,
      ))
      ..addPath(_createCrystalPath(cropRect.shift(videoOffset)), Offset.zero);
    
    canvas.drawPath(overlayPath, overlayPaint);
    
    // Draw crystal border
    final Paint borderPaint = Paint()
      ..shader = ui.Gradient.linear(
        cropRect.topLeft.translate(videoOffset.dx, videoOffset.dy),
        cropRect.bottomRight.translate(videoOffset.dx, videoOffset.dy),
        [
          amethyst.withOpacity(0.8),
          sapphire.withOpacity(0.8),
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawPath(_createCrystalPath(cropRect.shift(videoOffset)), borderPaint);
    
    // Draw handles with crystal effect
    _drawCrystalHandles(canvas, videoOffset);
  }

  Path _createCrystalPath(Rect rect) {
    final Path path = Path();
    
    // Create crystal-like corners
    final double cornerSize = 20.0;
    
    path.moveTo(rect.left + cornerSize, rect.top);
    path.lineTo(rect.right - cornerSize, rect.top);
    path.lineTo(rect.right, rect.top + cornerSize);
    path.lineTo(rect.right, rect.bottom - cornerSize);
    path.lineTo(rect.right - cornerSize, rect.bottom);
    path.lineTo(rect.left + cornerSize, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cornerSize);
    path.lineTo(rect.left, rect.top + cornerSize);
    path.close();
    
    return path;
  }

  void _drawCrystalHandles(Canvas canvas, Offset videoOffset) {
    final Paint handlePaint = Paint()
      ..shader = ui.Gradient.radial(
        cropRect.center.translate(videoOffset.dx, videoOffset.dy),
        cropRect.width / 2,
        [
          amethyst.withOpacity(0.8 + 0.2 * crystalAnimation.value),
          sapphire.withOpacity(0.8 - 0.2 * crystalAnimation.value),
        ],
      );

    for (final Offset position in handlePositions) {
      // Draw crystal handle
      final Path handlePath = Path();
      handlePath.addPolygon([
        position.translate(videoOffset.dx, videoOffset.dy) + Offset(0, -_handleVisualSize),
        position.translate(videoOffset.dx, videoOffset.dy) + Offset(_handleVisualSize, 0),
        position.translate(videoOffset.dx, videoOffset.dy) + Offset(0, _handleVisualSize),
        position.translate(videoOffset.dx, videoOffset.dy) + Offset(-_handleVisualSize, 0),
      ], true);
      
      canvas.drawPath(handlePath, handlePaint);
      
      // Add glow effect
      final Paint glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3)
        ..color = crystalGlow.withOpacity(0.3 + 0.2 * crystalAnimation.value);
      
      canvas.drawPath(handlePath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 