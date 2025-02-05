import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:math' as math;

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
  bool _isPublic = true;

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
  }

  @override
  void dispose() {
    _videoController.dispose();
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _pulseController.dispose();
    super.dispose();
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

                        // Visibility toggle
                        _buildVisibilityToggle(),
                        const SizedBox(height: 32),

                        // Shareable link
                        _buildShareableLink(),
                        const SizedBox(height: 32),

                        // Action buttons
                        _buildActionButtons(),
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
    return AspectRatio(
      aspectRatio: 9 / 16,
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
              VideoPlayer(_videoController),
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
          subtitle: 'Keep your gem in your local collection',
          onTap: () {
            // TODO: Implement save to device
            HapticFeedback.mediumImpact();
          },
        ),
        const SizedBox(height: 16),
        _buildShareOption(
          icon: Icons.camera_alt,
          title: 'Share to Instagram',
          subtitle: _isInstagramConnected 
            ? 'Ready to share'
            : 'Connect your Instagram account',
          onTap: () {
            // TODO: Implement Instagram sharing
            HapticFeedback.mediumImpact();
          },
          isConnected: _isInstagramConnected,
        ),
      ],
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isConnected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Icon(
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
            Icon(
              Icons.arrow_forward_ios,
              color: silver,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
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
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? emerald : ruby,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visibility',
                  style: gemText.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isPublic 
                    ? 'Anyone with the link can view'
                    : 'Only you can view',
                  style: gemText.copyWith(
                    color: silver,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() => _isPublic = value);
              HapticFeedback.lightImpact();
            },
            activeColor: emerald,
            activeTrackColor: emerald.withOpacity(0.3),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GemButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            gemColor: ruby,
            style: GemButtonStyle.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GemButton(
            text: 'Publish Gem',
            onPressed: () {
              // TODO: Implement publish
              HapticFeedback.mediumImpact();
            },
            gemColor: emerald,
            isAnimated: true,
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

class _GemButtonPainter extends CustomPainter {
  final double progress;

  _GemButtonPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * math.pi),
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GemButtonPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 