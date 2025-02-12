import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../theme/gem_theme.dart';

class CrystalVideoPlayerPage extends StatefulWidget {
  final VideoPlayerController videoController;
  
  const CrystalVideoPlayerPage({
    super.key,
    required this.videoController,
  });

  @override
  State<CrystalVideoPlayerPage> createState() => _CrystalVideoPlayerPageState();
}

class _CrystalVideoPlayerPageState extends State<CrystalVideoPlayerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controlsOpacityController;
  bool _showControls = true;
  bool _isDraggingProgress = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controls opacity animation
    _controlsOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsOpacityController.dispose();
    super.dispose();
  }

  void _startControlsTimer() {
    if (!_isDraggingProgress) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls && !_isDraggingProgress) {
          setState(() => _showControls = false);
          _controlsOpacityController.reverse();
        }
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsOpacityController.forward();
      _startControlsTimer();
    } else {
      _controlsOpacityController.reverse();
    }
    HapticFeedback.mediumImpact();
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.videoController.value.isPlaying) {
        widget.videoController.pause();
      } else {
        widget.videoController.play();
        _startControlsTimer();
      }
    });
    HapticFeedback.mediumImpact();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          GestureDetector(
            onTap: _toggleControls,
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.videoController.value.aspectRatio,
                child: VideoPlayer(widget.videoController),
              ),
            ),
          ),

          // Crystal overlay effect
          Positioned.fill(
            child: CustomPaint(
              painter: _CrystalOverlayPainter(
                color: deepCave.withOpacity(0.1),
              ),
            ),
          ),

          // Controls overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: AnimatedBuilder(
                animation: _controlsOpacityController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controlsOpacityController.value,
                    child: _showControls ? child : const SizedBox.shrink(),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top bar
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        // Bottom controls
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            ValueListenableBuilder(
                              valueListenable: widget.videoController,
                              builder: (context, VideoPlayerValue value, child) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 2,
                                          activeTrackColor: emerald,
                                          inactiveTrackColor: silver.withOpacity(0.3),
                                          thumbColor: emerald,
                                          overlayColor: emerald.withOpacity(0.3),
                                          thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6,
                                          ),
                                          overlayShape: const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                        ),
                                        child: Slider(
                                          value: value.position.inMilliseconds.toDouble(),
                                          min: 0,
                                          max: value.duration.inMilliseconds.toDouble(),
                                          onChangeStart: (_) {
                                            _isDraggingProgress = true;
                                          },
                                          onChanged: (newPosition) {
                                            widget.videoController.seekTo(
                                              Duration(milliseconds: newPosition.toInt()),
                                            );
                                          },
                                          onChangeEnd: (_) {
                                            _isDraggingProgress = false;
                                            _startControlsTimer();
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(value.position),
                                              style: gemText.copyWith(
                                                color: silver,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(value.duration),
                                              style: gemText.copyWith(
                                                color: silver,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Play/Pause button
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 32,
                                top: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: deepCave.withOpacity(0.6),
                                      border: Border.all(
                                        color: emerald.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        widget.videoController.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrystalOverlayPainter extends CustomPainter {
  final Color color;

  _CrystalOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final rng = math.Random(42); // Fixed seed for consistent pattern

    // Create crystalline pattern
    for (var i = 0; i < 10; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final points = <Offset>[];
      
      // Generate crystal shape
      for (var j = 0; j < 6; j++) {
        final angle = (j / 6) * 2 * math.pi;
        final radius = 20 + rng.nextDouble() * 40;
        points.add(Offset(
          startX + math.cos(angle) * radius,
          startY + math.sin(angle) * radius,
        ));
      }

      // Draw crystal
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrystalOverlayPainter oldDelegate) => false;
} 