import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:io';
import 'feed_page.dart';

class VideoPreviewPage extends StatefulWidget {
  final XFile videoFile;

  const VideoPreviewPage({
    super.key,
    required this.videoFile,
  });

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _shimmerController;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.file(
        File(widget.videoFile.path),
      );

      await _controller.initialize();
      await _controller.setLooping(true);
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load video: \$e');
    }
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller.play() : _controller.pause();
    });
    HapticFeedback.mediumImpact();
  }

  void _navigateToFeed() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          FeedPage(recordedVideos: [File(widget.videoFile.path)]),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: caveTransition,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_controller.value.isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Video Preview
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          ),

          // Shimmering overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _VideoOverlayPainter(
                    progress: _shimmerController.value,
                  ),
                );
              },
            ),
          ),

          // Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControls(),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: deepCave,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ruby,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Error',
              style: crystalHeading.copyWith(color: ruby),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: gemText.copyWith(color: silver),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GemButton(
              text: 'Try Again',
              onPressed: _initializeVideoPlayer,
              gemColor: emerald,
              isAnimated: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: deepCave,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(amethyst),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Video',
              style: crystalHeading.copyWith(color: amethyst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: caveShadow.withOpacity(0.3),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 16,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: silver,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Text(
                'Preview',
                style: crystalHeading.copyWith(fontSize: 24),
              ),
              const Spacer(),
              GemButton(
                text: 'Use Video',
                onPressed: _navigateToFeed,
                gemColor: emerald,
                isAnimated: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: caveShadow.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: 24),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.replay_10,
                    color: sapphire,
                    onPressed: () {
                      final newPosition = _controller.value.position - 
                          const Duration(seconds: 10);
                      _controller.seekTo(newPosition);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                  _buildPlayButton(),
                  _buildControlButton(
                    icon: Icons.forward_10,
                    color: sapphire,
                    onPressed: () {
                      final newPosition = _controller.value.position + 
                          const Duration(seconds: 10);
                      _controller.seekTo(newPosition);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: amethyst,
                inactiveTrackColor: amethyst.withOpacity(0.3),
                thumbColor: amethyst,
                overlayColor: amethyst.withOpacity(0.2),
              ),
              child: Slider(
                value: value.position.inMilliseconds.toDouble(),
                min: 0,
                max: value.duration.inMilliseconds.toDouble(),
                onChanged: (position) {
                  _controller.seekTo(Duration(
                    milliseconds: position.toInt(),
                  ));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: color,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: emerald.withOpacity(0.3),
          border: Border.all(
            color: emerald.withOpacity(0.7),
            width: 4,
          ),
        ),
        child: Center(
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: emerald,
            size: 40,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '\$minutes:\$seconds';
  }
}

class _VideoOverlayPainter extends CustomPainter {
  final double progress;

  _VideoOverlayPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
          ruby.withOpacity(0.1),
        ],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * 3.14159),
      ).createShader(Offset.zero & size);

    // Draw frame
    final frameWidth = 2.0;
    final rect = Rect.fromLTWH(
      frameWidth / 2,
      frameWidth / 2,
      size.width - frameWidth,
      size.height - frameWidth,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_VideoOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 