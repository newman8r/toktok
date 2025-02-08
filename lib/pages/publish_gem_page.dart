/*
 * PublishGemPage: Video publishing and sharing interface
 * 
 * Handles the final steps of content publishing with:
 * - Privacy settings configuration
 * - Platform-specific sharing options
 * - Upload progress visualization
 * - Success/error state handling
 * 
 * Implements a streamlined publishing flow while maintaining
 * the crystal theme through animations and visual effects.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'email_crystal_chamber.dart';

class PublishGemPage extends StatefulWidget {
  final String cloudinaryUrl;

  const PublishGemPage({
    super.key,
    required this.cloudinaryUrl,
  });

  @override
  State<PublishGemPage> createState() => _PublishGemPageState();
}

class _PublishGemPageState extends State<PublishGemPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _shimmerController;
  late AnimationController _crystalGrowthController;
  late AnimationController _pulseController;
  
  bool _isInstagramConnected = false;
  String? _shareableLink;
  bool _isSaving = false;
  bool _showSuccessParticles = false;
  late final AnimationController _particleController;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: crystalGrow,
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _videoController = VideoPlayerController.network(widget.cloudinaryUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _videoController.play();
            _videoController.setLooping(true);
          });
        }
      });

    // Generate shareable link (placeholder for now)
    _shareableLink = '${widget.cloudinaryUrl}?player=true';

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _particleController.addListener(() {
      for (var particle in _particles) {
        particle.update(_particleController.value);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _saveToDevice() async {
    try {
      setState(() => _isSaving = true);

      // Request appropriate permissions based on Android version
      bool hasPermission = false;
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          hasPermission = true;
        } else if (await Permission.manageExternalStorage.request().isGranted) {
          hasPermission = true;
        }
      } else {
        // For iOS, we don't need explicit permission for saving to app's directory
        hasPermission = true;
      }

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to save the video')),
        );
        return;
      }

      // Get the appropriate directory
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');  // Android Downloads folder
        if (!await directory.exists()) {
          // Fallback to app's external storage
          final appDir = await getExternalStorageDirectory();
          if (appDir == null) {
            throw Exception('Could not access storage directory');
          }
          directory = appDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();  // iOS Documents directory
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/TokTok_Gem_$timestamp.mp4';

      // Download and save the video
      final response = await http.get(Uri.parse(widget.cloudinaryUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to ${Platform.isAndroid ? 'Downloads' : 'Documents'} folder'),
              backgroundColor: Colors.green,
            ),
          );
          // Trigger success particles
          setState(() => _showSuccessParticles = true);
          _particleController.forward(from: 0);
          HapticFeedback.mediumImpact();
        }
      } else {
        throw Exception('Failed to download video');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _generateParticles() {
    _particles.clear();
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    for (var i = 0; i < 50; i++) {
      _particles.add(_Particle(
        center: center,
        angle: math.Random().nextDouble() * 2 * math.pi,
        speed: math.Random().nextDouble() * 200 + 100,
        color: [emerald, amethyst, sapphire][math.Random().nextInt(3)],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Animated crystal cave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CrystalBackgroundPainter(
                    progress: _shimmerController.value,
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Crystal App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: FlexibleSpaceBar(
                        title: Text(
                          'Share Your Gem',
                          style: crystalHeading.copyWith(fontSize: 24),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                amethyst.withOpacity(0.3),
                                deepCave.withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: silver),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Video preview
                        _buildVideoPreview(),
                        const SizedBox(height: 32),

                        // Share options
                        Text(
                          'Share Options',
                          style: crystalHeading.copyWith(
                            fontSize: 20,
                            color: amethyst,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildShareOptions(),
                        const SizedBox(height: 32),

                        // Shareable link
                        _buildShareableLink(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_videoController.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate the correct aspect ratio based on rotation
    final isRotated = _videoController.value.rotationCorrection % 180 != 0;
    final videoWidth = _videoController.value.size.width;
    final videoHeight = _videoController.value.size.height;
    final aspectRatio = isRotated 
        ? videoHeight / videoWidth 
        : videoWidth / videoHeight;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(emeraldCut),
          boxShadow: [
            BoxShadow(
              color: sapphire.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(emeraldCut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.rotate(
                angle: _videoController.value.rotationCorrection * math.pi / 180,
                child: VideoPlayer(_videoController),
              ),
              // Crystal overlay
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CrystalOverlayPainter(
                      progress: _shimmerController.value,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOptions() {
    return Column(
      children: [
        _buildShareOption(
          icon: Icons.save_alt,
          title: 'Save to Device',
          subtitle: _isSaving 
            ? 'Saving your gem...'
            : 'Keep your gem in your local collection',
          onTap: _isSaving ? null : _saveToDevice,
          isLoading: _isSaving,
        ),
        const SizedBox(height: 16),
        _buildShareOption(
          icon: Icons.email,
          title: 'Share via Email',
          subtitle: 'Send your gem through email',
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => 
                  EmailCrystalChamber(cloudinaryUrl: widget.cloudinaryUrl),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutQuart;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          isConnected: false,
        ),
      ],
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isConnected = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: caveShadow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(emeraldCut),
              border: Border.all(
                color: amethyst.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: deepCave.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(emeraldCut / 2),
                  ),
                  child: isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(emerald),
                        strokeWidth: 2,
                      )
                    : Icon(
                        icon,
                        color: isConnected ? emerald : silver,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: gemText.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: gemText.copyWith(
                          color: silver,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: silver,
                    size: 16,
                  ),
              ],
            ),
          ),
          if (_showSuccessParticles)
            CustomPaint(
              painter: _ParticlesPainter(particles: _particles),
              size: Size.infinite,
            ),
        ],
      ),
    );
  }

  Widget _buildShareableLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shareable Link',
          style: crystalHeading.copyWith(
            fontSize: 20,
            color: amethyst,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: caveShadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: amethyst.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _shareableLink ?? '',
                  style: gemText.copyWith(
                    color: silver,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  // TODO: Implement copy to clipboard
                  HapticFeedback.mediumImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: deepCave.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(emeraldCut / 2),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: silver,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrystalBackgroundPainter extends CustomPainter {
  final double progress;

  _CrystalBackgroundPainter({required this.progress});

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
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_CrystalBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CrystalOverlayPainter extends CustomPainter {
  final double progress;

  _CrystalOverlayPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * math.pi),
      ).createShader(Offset.zero & size);

    // Draw crystal facets
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Create crystal-like pattern
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * math.pi;
      final x = centerX + math.cos(angle) * size.width * 0.5;
      final y = centerY + math.sin(angle) * size.height * 0.5;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrystalOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final Offset center;
  final double angle;
  final double speed;
  final Color color;
  late Offset position;
  late double alpha;

  _Particle({
    required this.center,
    required this.angle,
    required this.speed,
    required this.color,
  }) {
    position = center;
    alpha = 1.0;
  }

  void update(double progress) {
    final distance = speed * progress;
    position = Offset(
      center.dx + math.cos(angle) * distance,
      center.dy + math.sin(angle) * distance,
    );
    alpha = 1.0 - progress;
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw particle trail
      final path = Path();
      path.moveTo(
        particle.center.dx,
        particle.center.dy,
      );
      path.lineTo(
        particle.position.dx,
        particle.position.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
} 