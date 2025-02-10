/*
 * VideoCropPage: Precision video trimming interface
 * 
 * Provides advanced video editing capabilities:
 * - Frame-accurate trimming with preview
 * - Custom crystal lens UI for trim handles
 * - Real-time preview of trimmed content
 * - Progress tracking for processing
 * 
 * Uses custom painting for the unique crystal-themed
 * trimming interface while ensuring precise control.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../services/gem_service.dart';
import '../pages/gem_gallery_page.dart';
import '../pages/gem_meta_edit_page.dart';

class VideoCropPage extends StatefulWidget {
  final String videoUrl;
  final Function(String) onCropComplete;
  final String? sourceGemId;

  const VideoCropPage({
    Key? key,
    required this.videoUrl,
    required this.onCropComplete,
    this.sourceGemId,
  }) : super(key: key);

  @override
  _VideoCropPageState createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> {
  late VideoEditorController _controller;
  bool _isExporting = false;
  String _exportText = '';
  final _authService = AuthService();
  final _gemService = GemService();

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    print('Starting video editor initialization...');
    
    // Download video file from URL first
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${tempDir.path}/temp_video_$timestamp.mp4';
    print('Temp video path: $tempPath');
    
    final videoFile = File(tempPath);
    print('Downloading video from URL: ${widget.videoUrl}');
    final response = await http.get(Uri.parse(widget.videoUrl));
    await videoFile.writeAsBytes(response.bodyBytes);
    print('Video downloaded successfully');

    print('Creating VideoEditorController...');
    _controller = VideoEditorController.file(
      videoFile,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(minutes: 10),
    );
    
    try {
      print('Initializing controller...');
      await _controller.initialize();
      print('Controller initialized successfully');
      setState(() {});
    } catch (e, stackTrace) {
      print('Error initializing video editor: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool?> _showMetadataPromptModal(String gemId) async {
    HapticFeedback.mediumImpact();
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: deepCave.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(emeraldCut),
              side: BorderSide(
                color: amethyst.withOpacity(0.3),
                width: 1,
              ),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: gold,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Gem is Ready! ✨',
                  style: crystalHeading.copyWith(
                    fontSize: 24,
                    color: amethyst,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Would you like to add a title, description, and tags to your creation? 💎',
                  style: gemText.copyWith(
                    color: silver,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(emeraldCut),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(true);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Add Details ✍️',
                            style: gemText.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'No Thanks 👋',
                        style: gemText.copyWith(
                          color: silver.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportVideo() async {
    setState(() {
      _isExporting = true;
      _exportText = 'Crystallizing your creation...';
    });

    try {
      print('Starting video export...');
      
      // Get the crop rect and rotation from the controller
      final minCrop = _controller.cacheMinCrop;
      final maxCrop = _controller.cacheMaxCrop;
      final rotation = _controller.rotation;
      
      print('Debug - Original crop values:');
      print('minCrop: $minCrop');
      print('maxCrop: $maxCrop');
      
      // Get trim values using the correct properties
      final startTrim = _controller.minTrim;
      final endTrim = _controller.maxTrim;
      
      print('Crop points: $minCrop - $maxCrop');
      print('Rotation: $rotation');
      print('Trim points: $startTrim - $endTrim');

      // Initialize Cloudinary service
      final cloudinaryService = CloudinaryService();
      
      // Create transformation string for Cloudinary
      final List<String> transformations = [];
      
      // Add crop transformation if needed
      if (minCrop != const Offset(0, 0) || maxCrop != const Offset(1, 1)) {
        final videoWidth = _controller.video.value.size.width;
        final videoHeight = _controller.video.value.size.height;
        
        print('Debug - Video dimensions:');
        print('Width: $videoWidth');
        print('Height: $videoHeight');
        
        final x = (minCrop.dx * videoWidth).round();
        final y = (minCrop.dy * videoHeight).round();
        final width = ((maxCrop.dx - minCrop.dx) * videoWidth).round();
        final height = ((maxCrop.dy - minCrop.dy) * videoHeight).round();
        
        print('Debug - Calculated crop parameters:');
        print('x: $x');
        print('y: $y');
        print('width: $width');
        print('height: $height');
        
        // Ensure crop parameters are valid
        if (width > 0 && height > 0 && 
            x >= 0 && y >= 0 && 
            x + width <= videoWidth && 
            y + height <= videoHeight) {
          transformations.add('c_crop,w_$width,h_$height,x_$x,y_$y');
          print('Debug - Added crop transformation: c_crop,w_$width,h_$height,x_$x,y_$y');
        } else {
          print('Debug - Invalid crop parameters, skipping crop transformation');
        }
      } else {
        print('Debug - No crop needed (full frame)');
      }
      
      // Add rotation if needed
      if (rotation != 0) {
        transformations.add('a_$rotation');
      }
      
      // Add trim if needed (convert from percentage to milliseconds)
      if (startTrim > 0 || endTrim < 1) {
        final videoDurationMs = _controller.video.value.duration.inMilliseconds;
        final startMs = (startTrim * videoDurationMs).round();
        final durationMs = ((endTrim - startTrim) * videoDurationMs).round();
        transformations.add('so_$startMs,du_$durationMs');
      }
      
      // Create timestamp and parameters for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'gem_${DateTime.now().millisecondsSinceEpoch}';
      
      // Parameters to sign (in alphabetical order)
      final Map<String, String> paramsToSign = {
        'folder': 'toktok_videos',
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };
      
      if (transformations.isNotEmpty) {
        paramsToSign['transformation'] = transformations.join('/');
      }
      
      print('Uploading to Cloudinary with transformations: ${transformations.join('/')}');
      
      // Upload the video with transformations
      final cloudinaryUrl = await cloudinaryService.uploadVideo(
        File(_controller.file.path),
        publicId: publicId,
        timestamp: timestamp,
        paramsToSign: paramsToSign,
      );
      
      if (cloudinaryUrl != null) {
        print('Upload successful: $cloudinaryUrl');
        
        // Get current user
        final user = await _authService.currentUser;
        if (user == null) throw Exception('User not authenticated');

        // Create gem in Firestore
        final gem = await _gemService.createGem(
          userId: user.uid,
          title: 'My Crystal Creation', // Default title, can be edited later
          description: 'Created with Crystal Lens', // Default description
          cloudinaryUrl: cloudinaryUrl,
          cloudinaryPublicId: publicId,
          bytes: await File(_controller.file.path).length(),
          tags: ['crystal_lens'],
          sourceGemId: widget.sourceGemId,
        );

        if (!mounted) return;

        setState(() => _isExporting = false);

        // Show metadata prompt
        final bool shouldEditMetadata = await _showMetadataPromptModal(gem.id) ?? false;

        if (shouldEditMetadata && mounted) {
          // Navigate to metadata edit page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GemMetaEditPage(
                gemId: gem.id,
                gem: gem,
              ),
            ),
          );
        } else if (mounted) {
          // Navigate to gem gallery
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const GemGalleryPage()),
            (route) => false,
          );
        }
      } else {
        print('Upload failed: null URL returned');
        setState(() {
          _exportText = 'Upload failed';
        });
      }
    } catch (e, stackTrace) {
      print('Error during export: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _exportText = 'Export failed: $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    try {
      if (!_controller.initialized) {
        return _buildLoadingScreen();
      }
      
      return Scaffold(
        backgroundColor: deepCave,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          _buildTabBar(),
                          Expanded(
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildCropTab(),
                                _buildTrimTab(),
                                _buildRotateTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isExporting) _buildExportingOverlay(),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in build: $e');
      return _buildLoadingScreen();
    }
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: caveShadow,
        boxShadow: [
          BoxShadow(
            color: amethyst.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Crystal Lens',
            style: crystalHeading.copyWith(fontSize: 24),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _exportVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: caveShadow,
      child: TabBar(
        indicatorColor: amethyst,
        labelColor: amethyst,
        unselectedLabelColor: silver,
        tabs: const [
          Tab(icon: Icon(Icons.crop), text: 'Crop'),
          Tab(icon: Icon(Icons.content_cut), text: 'Trim'),
          Tab(icon: Icon(Icons.rotate_right), text: 'Rotate'),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    return Container(
      color: deepCave,
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CoverViewer(controller: _controller),
                  CropGridViewer.edit(
                    controller: _controller,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  // Video play/pause button
                  if (_controller.initialized && !_controller.isPlaying)
                    GestureDetector(
                      onTap: () => _controller.video.play(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow, color: deepCave),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildCropActions(),
        ],
      ),
    );
  }

  Widget _buildTrimTab() {
    return Container(
      color: deepCave,
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _controller.initialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CoverViewer(
                          controller: _controller,
                        ),
                        Center(
                          child: CropGridViewer.preview(
                            controller: _controller,
                          ),
                        ),
                        // Video play/pause button
                        if (!_controller.isPlaying)
                          GestureDetector(
                            onTap: () => _controller.video.play(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.play_arrow, color: deepCave),
                            ),
                          ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Container(
            color: caveShadow,
            child: TrimSlider(
              controller: _controller,
              height: 60,
              child: TrimTimeline(
                controller: _controller,
                padding: const EdgeInsets.only(top: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotateTab() {
    return Container(
      color: deepCave,
      child: Column(
        children: [
          // Add video preview with rotation
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _controller.initialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CoverViewer(controller: _controller),
                        Center(
                          child: CropGridViewer.preview(
                            controller: _controller,
                          ),
                        ),
                        // Video play/pause button
                        if (!_controller.isPlaying)
                          GestureDetector(
                            onTap: () => _controller.video.play(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.play_arrow, color: deepCave),
                            ),
                          ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          // Rotation controls
          Container(
            color: caveShadow,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRotateButton(
                  icon: Icons.rotate_left,
                  label: 'Rotate Left',
                  onPressed: () => _controller.rotate90Degrees(RotateDirection.left),
                ),
                _buildRotateButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate Right',
                  onPressed: () => _controller.rotate90Degrees(RotateDirection.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotateButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: amethyst, size: 48),
          onPressed: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: gemText.copyWith(
            color: silver,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCropActions() {
    return Container(
      color: caveShadow,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAspectRatioButton('1:1', 1.0),
          _buildAspectRatioButton('4:5', 0.8),
          _buildAspectRatioButton('16:9', 16.0 / 9.0),
          _buildAspectRatioButton('Free', null),
        ],
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, double? ratio) {
    final isSelected = _controller.preferredCropAspectRatio == ratio;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? amethyst : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            _controller.preferredCropAspectRatio = ratio;
          });
        },
        child: Text(
          label,
          style: gemText.copyWith(
            color: isSelected ? amethyst : silver,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExportingOverlay() {
    return Container(
      color: deepCave.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(amethyst),
            ),
            const SizedBox(height: 16),
            Text(
              _exportText,
              style: gemText.copyWith(color: silver),
              textAlign: TextAlign.center,
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(amethyst),
            ),
            const SizedBox(height: 16),
            Text(
              'Preparing Crystal Lens...',
              style: gemText.copyWith(color: silver),
            ),
          ],
        ),
      ),
    );
  }
}

class OpacityTransition extends StatelessWidget {
  final Widget child;
  final bool visible;
  final Duration duration;

  const OpacityTransition({
    Key? key,
    required this.child,
    required this.visible,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      child: child,
    );
  }
} 