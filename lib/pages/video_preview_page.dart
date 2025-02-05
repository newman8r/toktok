import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:io';
import 'gem_explorer_page.dart';
import '../services/cloudinary_service.dart';
import '../services/gem_service.dart';
import '../services/auth_service.dart';
import 'gem_gallery_page.dart';

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
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final GemService _gemService = GemService();
  final AuthService _authService = AuthService();

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

  void _navigateToGemExplorer() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: deepCave.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: emerald),
              const SizedBox(height: 16),
              Text(
                'Processing video...',
                style: gemText.copyWith(color: silver),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Initialize Cloudinary service
      final cloudinary = CloudinaryService();
      
      // Upload video to Cloudinary
      final cloudinaryUrl = await cloudinary.uploadVideo(
        File(widget.videoFile.path),
      );

      if (!mounted) return;
      
      if (cloudinaryUrl != null) {
        // Create gem in Firestore
        final gem = await _gemService.createGem(
          userId: user.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          cloudinaryUrl: cloudinaryUrl,
          cloudinaryPublicId: cloudinaryUrl.split('/').last.split('.').first,
          bytes: await File(widget.videoFile.path).length(),
        );

        if (!mounted) return;
        
        // Close loading dialog
        Navigator.pop(context);

        // Navigate back to GemGallery
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              const GemGalleryPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: caveTransition,
          ),
          (route) => false,  // Remove all previous routes
        );
      } else {
        throw Exception('Failed to upload video to Cloudinary');
      }
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error processing video: $e',
            style: gemText.copyWith(color: Colors.white),
          ),
          backgroundColor: ruby.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

          // Form overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: caveShadow.withOpacity(0.5),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: gemText.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: gemText.copyWith(color: silver),
                            filled: true,
                            fillColor: deepCave.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: gemText.copyWith(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: gemText.copyWith(color: silver),
                            filled: true,
                            fillColor: deepCave.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
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
                                text: 'Share Gem',
                                onPressed: _navigateToGemExplorer,
                                gemColor: emerald,
                                isAnimated: true,
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

          // Controls
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top,
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
            ],
          ),
        ),
      ),
    );
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