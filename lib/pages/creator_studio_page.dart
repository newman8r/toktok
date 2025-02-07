/*
 * CreatorStudioPage: Main creation and management hub
 * 
 * Serves as the central dashboard for content creation with:
 * - Video recording and file upload options
 * - Collection statistics and insights
 * - Quick access to gallery and editing tools
 * - Animated crystal-themed backgrounds
 * 
 * This page acts as the main navigation hub, providing a welcoming
 * and inspiring space for content creators while maintaining the
 * app's crystal cave aesthetic.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/gem_service.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'camera_page.dart';
import 'gem_gallery_page.dart';
import 'package:image_picker/image_picker.dart';

class CreatorStudioPage extends StatefulWidget {
  const CreatorStudioPage({super.key});

  @override
  State<CreatorStudioPage> createState() => _CreatorStudioPageState();
}

class _CreatorStudioPageState extends State<CreatorStudioPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GemService _gemService = GemService();
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _shimmerController;
  late final AnimationController _sparkleController;
  int _totalGems = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadGemCount();
  }

  Future<void> _loadGemCount() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final gems = await _gemService.getUserGems(user.uid);
        if (mounted) {
          setState(() {
            _totalGems = gems.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading gem count: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Background shimmer effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CreatorStudioBackgroundPainter(
                    progress: _shimmerController.value,
                  ),
                );
              },
            ),
          ),
          
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 32),
                      _buildUploadSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      title: Text(
        'Creator Studio',
        style: crystalHeading.copyWith(fontSize: 20),
      ),
      actions: [
        // Gallery button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.collections, color: silver),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                    const GemGalleryPage(),
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
            },
            tooltip: 'View Gem Collection',
          ),
        ),
        // Logout button
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.logout, color: silver),
            onPressed: () async {
              try {
                await _authService.signOut();
                print('👋 User logged out successfully');
              } catch (e) {
                print('❌ Error logging out: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error logging out: $e',
                        style: gemText.copyWith(color: Colors.white),
                      ),
                      backgroundColor: ruby.withOpacity(0.8),
                    ),
                  );
                }
              }
            },
            tooltip: 'Sign Out',
          ),
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
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Your Creative Space',
            style: crystalHeading.copyWith(
              fontSize: 28,
              color: amethyst,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: _buildFancyGemButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFancyGemButton() {
    return GestureDetector(
      onTapDown: (_) => _sparkleController.forward(from: 0),
      onTapUp: (_) {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              const GemGalleryPage(),
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
      },
      child: Stack(
        children: [
          // Animated background shimmer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _GemButtonPainter(
                  shimmerProgress: _shimmerController.value,
                  sparkleProgress: _sparkleController.value,
                ),
              );
            },
          ),
          
          // Content
          Container(
            width: 200,
            height: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.diamond,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'View My Library',
                  style: crystalHeading.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: amethyst.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (!_isLoading) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: deepCave.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: amethyst.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '$_totalGems Gems',
                      style: gemText.copyWith(
                        color: silver,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUploadOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  color: emerald,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => 
                          const CameraPage(),
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
                  },
                ),
                const SizedBox(width: 32),
                _buildUploadOption(
                  icon: Icons.upload_file,
                  label: 'Upload File',
                  color: sapphire,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _pickFile();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: gemText.copyWith(
              color: silver,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final XFile? mediaFile = await _picker.pickMedia(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (mediaFile != null) {
        // Show preview dialog with upload form
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _UploadDialog(
              mediaFile: mediaFile,
              onUploadComplete: () {
                Navigator.pushAndRemoveUntil(
                  context,
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
                  (route) => false,
                );
              },
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting file: $e',
              style: gemText.copyWith(color: Colors.white),
            ),
            backgroundColor: ruby.withOpacity(0.8),
          ),
        );
      }
      print('❌ Error picking file: $e');
    }
  }
}

class _CreatorStudioBackgroundPainter extends CustomPainter {
  final double progress;

  _CreatorStudioBackgroundPainter({required this.progress});

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
        stops: [
          0.0,
          0.5,
          1.0,
        ],
        transform: GradientRotation(progress * 2 * 3.14159),
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_CreatorStudioBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _UploadDialog extends StatefulWidget {
  final XFile mediaFile;
  final VoidCallback onUploadComplete;

  const _UploadDialog({
    required this.mediaFile,
    required this.onUploadComplete,
  });

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cloudinaryService = CloudinaryService();
  final _gemService = GemService();
  final _authService = AuthService();
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload to Cloudinary
      final cloudinaryUrl = await _cloudinaryService.uploadVideo(
        File(widget.mediaFile.path),
      );

      if (!mounted) return;
      
      if (cloudinaryUrl != null) {
        // Create gem in Firestore
        await _gemService.createGem(
          userId: user.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          cloudinaryUrl: cloudinaryUrl,
          cloudinaryPublicId: cloudinaryUrl.split('/').last.split('.').first,
          bytes: await File(widget.mediaFile.path).length(),
        );

        if (!mounted) return;
        widget.onUploadComplete();
      } else {
        throw Exception('Failed to upload to Cloudinary');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading file: $e',
            style: gemText.copyWith(color: Colors.white),
          ),
          backgroundColor: ruby.withOpacity(0.8),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: deepCave,
          borderRadius: BorderRadius.circular(emeraldCut),
          border: Border.all(
            color: amethyst.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: _isUploading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: emerald),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading...',
                    style: gemText.copyWith(color: silver),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload Details',
                      style: crystalHeading.copyWith(
                        fontSize: 24,
                        color: amethyst,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      style: gemText.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: gemText.copyWith(color: silver),
                        filled: true,
                        fillColor: caveShadow.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(emeraldCut),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
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
                        fillColor: caveShadow.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(emeraldCut),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: gemText.copyWith(color: silver),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GemButton(
                          text: 'Upload',
                          onPressed: _handleUpload,
                          gemColor: emerald,
                          isAnimated: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _GemButtonPainter extends CustomPainter {
  final double shimmerProgress;
  final double sparkleProgress;
  final _random = math.Random();

  _GemButtonPainter({
    required this.shimmerProgress,
    required this.sparkleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw gem base shape
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Iridescent gradient
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          amethyst.withOpacity(0.6),
          sapphire.withOpacity(0.6),
          emerald.withOpacity(0.6),
          ruby.withOpacity(0.6),
          amethyst.withOpacity(0.6),
        ],
        transform: GradientRotation(shimmerProgress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, paint);

    // Draw sparkles
    final sparkles = List.generate(12, (index) {
      final angle = index * (math.pi * 2 / 12);
      final distance = radius * (0.3 + 0.7 * _random.nextDouble());
      return Offset(
        center.dx + distance * math.cos(angle + sparkleProgress * 2 * math.pi),
        center.dy + distance * math.sin(angle + sparkleProgress * 2 * math.pi),
      );
    });

    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity((1 - sparkleProgress) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final sparkle in sparkles) {
      canvas.drawCircle(sparkle, 2 + 2 * _random.nextDouble(), sparklePaint);
    }

    // Draw facet lines
    final facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        facetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GemButtonPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
           oldDelegate.sparkleProgress != sparkleProgress;
  }
} 