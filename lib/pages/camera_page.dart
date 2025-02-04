import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'video_preview_page.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  CameraController? _controller;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  bool _isRecording = false;
  bool _isFrontCamera = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera and microphone permissions first
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      // Check camera and microphone permissions
      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        setState(() => _errorMessage = 'Camera and microphone permissions are required');
        return;
      }

      // For Android 10 and above, we don't need to request storage permission
      // For older Android versions, request storage permission
      if (await Permission.storage.status.isDenied) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isDenied) {
          debugPrint('Storage permission denied');
          // Continue anyway as we might not need it on newer Android versions
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }

      // Try to find front camera
      final frontCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front
      ).toList();

      // Use front camera if available, otherwise use the first available camera
      final camera = frontCameras.isNotEmpty ? frontCameras.first : cameras.first;
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      
      // Try to initialize with medium resolution first
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await _controller!.initialize();
      } catch (e) {
        // If medium fails, try with low resolution
        debugPrint('Failed to initialize with medium resolution, trying low: $e');
        await _controller!.dispose();
        
        _controller = CameraController(
          camera,
          ResolutionPreset.low,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _controller!.initialize();
      }
      
      // Basic camera configuration
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_controller == null) return;
    
    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    final newCameraIndex = _isFrontCamera ? 0 : 1;
    final newCamera = cameras[newCameraIndex];

    await _controller!.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,  // Use medium resolution for consistency
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to switch camera: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.mediumImpact();

    try {
      if (_isRecording) {
        final file = await _controller!.stopVideoRecording();
        setState(() => _isRecording = false);
        
        if (!mounted) return;
        
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              VideoPreviewPage(videoFile: file),
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
      } else {
        // Prepare for recording with more conservative settings
        await _controller!.prepareForVideoRecording();
        
        // Start recording with basic configuration
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to ${_isRecording ? "stop" : "start"} recording: $e');
      debugPrint('Recording error: $e');
      
      // Try to recover from error
      if (_isRecording) {
        setState(() => _isRecording = false);
        try {
          await _controller!.stopVideoRecording();
        } catch (e) {
          debugPrint('Error stopping recording during recovery: $e');
        }
      }
      
      // Reinitialize camera if needed
      if (e.toString().contains('broken pipe')) {
        _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: 9.0 / 16.0,  // Fixed vertical video aspect ratio
              child: ClipRect(
                child: Transform.scale(
                  scale: _getPreviewScale(),
                  alignment: Alignment.center,
                  child: CameraPreview(_controller!),
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
                  painter: _CameraOverlayPainter(
                    progress: _shimmerController.value,
                    isRecording: _isRecording,
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
              'Camera Error',
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
              onPressed: _initializeCamera,
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
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: amethyst.withOpacity(
                          0.3 + (_pulseController.value * 0.7),
                        ),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera,
                        color: amethyst.withOpacity(
                          0.5 + (_pulseController.value * 0.5),
                        ),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing Camera',
              style: crystalHeading.copyWith(color: amethyst),
            ),
          ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                color: sapphire,
                onPressed: _toggleCamera,
              ),
              _buildRecordButton(),
              _buildControlButton(
                icon: Icons.close,
                color: ruby,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? ruby.withOpacity(0.3) : emerald.withOpacity(0.3),
              border: Border.all(
                color: (_isRecording ? ruby : emerald).withOpacity(
                  _isRecording ? 1.0 : 0.3 + (_pulseController.value * 0.7),
                ),
                width: 4,
              ),
            ),
            child: Center(
              child: Icon(
                _isRecording ? Icons.stop : Icons.videocam,
                color: _isRecording ? ruby : emerald,
                size: 40,
              ),
            ),
          );
        },
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
              Text(
                'Create',
                style: crystalHeading.copyWith(fontSize: 24),
              ),
              const Spacer(),
              if (_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ruby.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(emeraldCut),
                    border: Border.all(
                      color: ruby.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: ruby,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recording',
                        style: gemText.copyWith(
                          color: ruby,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getPreviewScale() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0;
    }
    
    // Calculate scale to fill 9:16 container while maintaining aspect ratio
    final previewRatio = _controller!.value.aspectRatio;
    final targetRatio = 9.0 / 16.0;
    
    // Scale to fill the 9:16 container
    if (previewRatio > targetRatio) {
      // Preview is wider than container, scale by height
      return 1 / previewRatio * (16.0 / 9.0);
    } else {
      // Preview is taller than container, scale by width
      return 1.0;
    }
  }
}

class _CameraOverlayPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  _CameraOverlayPainter({
    required this.progress,
    required this.isRecording,
  });

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

    if (isRecording) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ruby.withOpacity(0.2),
          ruby.withOpacity(0.1),
          ruby.withOpacity(0.2),
        ],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * 3.14159),
      ).createShader(Offset.zero & size);
    }

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_CameraOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.isRecording != isRecording;
  }
} 