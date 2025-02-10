import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/gem_theme.dart';
import '../services/uberduck_service.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:just_audio/just_audio.dart';
import '../widgets/gem_button.dart';

class AIMusicPage extends StatefulWidget {
  final String videoPath;
  final VideoPlayerController videoController;

  const AIMusicPage({
    super.key,
    required this.videoPath,
    required this.videoController,
  });

  @override
  State<AIMusicPage> createState() => _AIMusicPageState();
}

class _AIMusicPageState extends State<AIMusicPage> with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _shimmerController;
  late AnimationController _crystalGrowthController;
  late AnimationController _loadingController;
  
  bool _isGenerating = false;
  bool _hasGenerated = false;
  String? _generatedAudioUrl;
  String? _errorMessage;
  bool _isVideoPlaying = false;

  // Crystal formation animation
  final List<_CrystalPoint> _crystalPoints = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize video controller
    widget.videoController.setVolume(0.5);  // Set video volume to 50% to blend with music
    _isVideoPlaying = widget.videoController.value.isPlaying;
    
    // Initialize shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Initialize crystal growth animation
    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Generate initial crystal points
    _generateCrystalPoints();
  }

  void _generateCrystalPoints() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _crystalPoints.add(
        _CrystalPoint(
          angle: i * (math.pi / 4) + random.nextDouble() * 0.5,
          distance: 50 + random.nextDouble() * 30,
          growthSpeed: 0.8 + random.nextDouble() * 0.4,
          color: [amethyst, sapphire, emerald][random.nextInt(3)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _audioPlayer.dispose();
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _loadingController.dispose();
    // Don't dispose video controller as it's managed by parent
    super.dispose();
  }

  void _toggleVideoPlayback() {
    setState(() {
      _isVideoPlaying = !_isVideoPlaying;
      if (_isVideoPlaying) {
        widget.videoController.play();
      } else {
        widget.videoController.pause();
      }
    });
  }

  Future<void> _generateMusic() async {
    if (_promptController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a prompt for your music');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Start the crystal growth animation
      _crystalGrowthController.forward(from: 0);
      
      // Generate the music
      final result = await UberduckService.generateSong(
        prompt: _promptController.text,
        model: 'melody-1',  // Specify the melody model
        shouldQuantize: true,
        includeTimepoints: false,
      );

      // Check status until complete
      String uuid = result['uuid'];
      bool isComplete = false;
      while (!isComplete) {
        final status = await UberduckService.checkStatus(uuid);
        if (status['finished']) {
          isComplete = true;
          setState(() {
            _generatedAudioUrl = status['audio_url'];
            _hasGenerated = true;
          });
          // Load and play the audio
          await _audioPlayer.setUrl(_generatedAudioUrl!);
          _audioPlayer.play();
          // Start video playback when music starts
          widget.videoController.play();
          setState(() => _isVideoPlaying = true);
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to generate music: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'AI Crystal Composer',
          style: crystalHeading.copyWith(fontSize: 24),
        ),
        actions: [
          // Add video playback toggle
          IconButton(
            icon: Icon(
              _isVideoPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: emerald,
            ),
            onPressed: _toggleVideoPlayback,
          ),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    amethyst.withOpacity(0.15),
                    deepCave.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background crystal formations
          CustomPaint(
            painter: _CrystalFormationPainter(
              shimmerProgress: _shimmerController.value,
              crystalPoints: _crystalPoints,
              growthProgress: _crystalGrowthController.value,
            ),
            size: Size.infinite,
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video preview at top
                    AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        child: VideoPlayer(widget.videoController),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prompt input
                    if (!_isGenerating && !_hasGenerated) ...[
                      Text(
                        'Describe your perfect background music:',
                        style: gemText.copyWith(
                          color: silver,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: caveShadow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(emeraldCut),
                          border: Border.all(
                            color: amethyst.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _promptController,
                          style: gemText.copyWith(color: silver),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'e.g., "A peaceful, ambient melody with gentle synths and soft piano"',
                            hintStyle: gemText.copyWith(
                              color: silver.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GemButton(
                        text: '✨ Generate Crystal Melody',
                        onPressed: _generateMusic,
                        gemColor: amethyst,
                        isAnimated: true,
                      ),
                    ],

                    // Loading state
                    if (_isGenerating)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CustomPaint(
                                painter: _CrystalLoadingPainter(
                                  progress: _loadingController.value,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Composing your crystal melody...',
                              style: gemText.copyWith(
                                color: silver,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a minute or two',
                              style: gemText.copyWith(
                                color: silver.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Generated music controls
                    if (_hasGenerated && _generatedAudioUrl != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                              color: emerald,
                              size: 32,
                            ),
                            onPressed: () {
                              if (_audioPlayer.playing) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
                              }
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(
                              Icons.replay,
                              color: sapphire,
                              size: 32,
                            ),
                            onPressed: () {
                              _audioPlayer.seek(Duration.zero);
                              _audioPlayer.play();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GemButton(
                            text: '🎵 Accept Melody',
                            onPressed: () {
                              // TODO: Handle accepting the melody
                              Navigator.pop(context, _generatedAudioUrl);
                            },
                            gemColor: emerald,
                            isAnimated: true,
                          ),
                          GemButton(
                            text: '✨ Try Again',
                            onPressed: () {
                              setState(() {
                                _hasGenerated = false;
                                _generatedAudioUrl = null;
                              });
                              _audioPlayer.stop();
                            },
                            gemColor: sapphire,
                            isAnimated: true,
                          ),
                        ],
                      ),
                    ],

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: gemText.copyWith(
                            color: ruby,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for crystal formation animation
class _CrystalPoint {
  final double angle;
  final double distance;
  final double growthSpeed;
  final Color color;

  _CrystalPoint({
    required this.angle,
    required this.distance,
    required this.growthSpeed,
    required this.color,
  });
}

// Crystal formation background painter
class _CrystalFormationPainter extends CustomPainter {
  final double shimmerProgress;
  final List<_CrystalPoint> crystalPoints;
  final double growthProgress;

  _CrystalFormationPainter({
    required this.shimmerProgress,
    required this.crystalPoints,
    required this.growthProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final point in crystalPoints) {
      final currentDistance = point.distance * growthProgress;
      final position = Offset(
        center.dx + math.cos(point.angle) * currentDistance,
        center.dy + math.sin(point.angle) * currentDistance,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            point.color.withOpacity(0.1),
            point.color.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(shimmerProgress * math.pi * 2),
        ).createShader(Rect.fromCenter(
          center: position,
          width: 40,
          height: 40,
        ));

      final path = Path();
      path.moveTo(position.dx, position.dy - 20);
      path.lineTo(position.dx + 20, position.dy);
      path.lineTo(position.dx, position.dy + 20);
      path.lineTo(position.dx - 20, position.dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrystalFormationPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
           oldDelegate.growthProgress != growthProgress;
  }
}

// Crystal loading animation painter
class _CrystalLoadingPainter extends CustomPainter {
  final double progress;

  _CrystalLoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + progress * math.pi * 2;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            amethyst.withOpacity(0.8),
            sapphire.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        ));

      final path = Path();
      path.moveTo(
        center.dx + math.cos(angle) * radius * 0.3,
        center.dy + math.sin(angle) * radius * 0.3,
      );
      path.lineTo(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      path.lineTo(
        center.dx + math.cos(angle + math.pi / 6) * radius * 0.8,
        center.dy + math.sin(angle + math.pi / 6) * radius * 0.8,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrystalLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 