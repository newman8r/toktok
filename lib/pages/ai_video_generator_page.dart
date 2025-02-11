import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../services/replicate_service.dart';
import '../services/cloudinary_service.dart';
import '../services/gem_service.dart';
import '../services/auth_service.dart';
import 'gem_gallery_page.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AIVideoGeneratorPage extends StatefulWidget {
  const AIVideoGeneratorPage({super.key});

  @override
  State<AIVideoGeneratorPage> createState() => _AIVideoGeneratorPageState();
}

class _AIVideoGeneratorPageState extends State<AIVideoGeneratorPage> with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  final _replicateService = ReplicateService();
  final _cloudinaryService = CloudinaryService();
  final _gemService = GemService();
  final _authService = AuthService();
  late final AnimationController _crystalController;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _crystalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _crystalController.dispose();
    super.dispose();
  }

  Future<void> _generateVideo() async {
    if (_promptController.text.isEmpty) {
      setState(() => _error = 'Please enter a prompt for your video');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      print('🎬 Starting AI video generation flow...');
      
      // Generate video with Replicate
      print('🤖 Generating video with Replicate...');
      final result = await _replicateService.generateVideo(
        prompt: _promptController.text,
      );

      if (!mounted) return;

      if (result['status'] == 'succeeded' && result['output'] != null) {
        final replicateUrl = result['output'] as String;
        print('✨ Replicate video generated: $replicateUrl');
        
        // Get current user
        final user = _authService.currentUser;
        if (user == null) throw Exception('User not authenticated');

        print('🌟 Uploading video to Cloudinary...');
        // Initialize Cloudinary service
        final cloudinaryService = CloudinaryService();
        
        // Download video from Replicate and upload to Cloudinary
        final response = await http.get(Uri.parse(replicateUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download video from Replicate');
        }

        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_video.mp4');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        print('📤 Uploading to Cloudinary...');
        // Upload to Cloudinary
        final cloudinaryUrl = await cloudinaryService.uploadVideo(
          tempFile,
          publicId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (cloudinaryUrl == null) {
          throw Exception('Failed to upload video to Cloudinary');
        }
        
        print('🎯 Video uploaded to Cloudinary: $cloudinaryUrl');

        // Create gem in Firestore with the Cloudinary URL
        await _gemService.createGem(
          userId: user.uid,
          title: 'AI Generated: ${_promptController.text.substring(0, math.min(30, _promptController.text.length))}...',
          description: _promptController.text,
          cloudinaryUrl: cloudinaryUrl,  // Use Cloudinary URL instead of Replicate URL
          cloudinaryPublicId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          bytes: 0,
          tags: ['ai_generated', 'replicate'],
        );

        // Clean up temp file
        await tempFile.delete();
        
        print('✅ AI video generation flow completed successfully!');

        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Your magical video has been created!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      } else {
        throw Exception('Video generation failed or output was null');
      }
    } catch (e) {
      print('❌ Error in video generation flow: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'AI Crystal Vision',
          style: crystalHeading.copyWith(fontSize: 24),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ruby.withOpacity(0.15),
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
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _crystalController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CrystalBackgroundPainter(
                    progress: _crystalController.value,
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Crystal-themed prompt card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: caveShadow.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(emeraldCut),
                      border: Border.all(
                        color: ruby.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Describe Your Vision',
                          style: crystalHeading.copyWith(
                            fontSize: 28,
                            color: ruby,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Let AI craft a magical video based on your prompt...',
                          style: gemText.copyWith(
                            color: silver,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _promptController,
                          style: gemText.copyWith(color: Colors.white),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter your video prompt here...',
                            hintStyle: gemText.copyWith(
                              color: silver.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: deepCave.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                              borderSide: BorderSide(
                                color: ruby.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                              borderSide: BorderSide(
                                color: ruby.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                              borderSide: const BorderSide(
                                color: ruby,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ruby.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(emeraldCut),
                              border: Border.all(
                                color: ruby.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: gemText.copyWith(
                                color: ruby,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isGenerating
                              ? Column(
                                  children: [
                                    const CircularProgressIndicator(
                                      color: ruby,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Crafting your vision...\nThis may take a few minutes',
                                      style: gemText.copyWith(
                                        color: silver,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                              : ElevatedButton(
                                  onPressed: _generateVideo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ruby.withOpacity(0.2),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 32,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(emeraldCut),
                                    ),
                                    side: BorderSide(
                                      color: ruby.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    'Generate Crystal Vision ✨',
                                    style: crystalHeading.copyWith(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          ruby.withOpacity(0.1),
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
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