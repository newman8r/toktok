/*
 * GemExplorerPage: Interactive video editing and exploration interface
 * 
 * Implements a unique spatial navigation system where editing options are
 * arranged in a hexagonal grid around the central video. Features include:
 * - Smooth spatial transitions between editing modes
 * - Crystal-themed UI with dynamic animations
 * - Video trimming and enhancement tools
 * - Metadata editing capabilities
 * - Intuitive gesture-based navigation
 * 
 * The hexagonal layout creates an immersive "crystal cave" feeling while
 * providing easy access to various editing tools and options.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'publish_gem_page.dart';
import 'video_crop_page.dart';
import 'package:flutter/rendering.dart';
import 'gem_meta_edit_page.dart';
import '../services/gem_service.dart';
import '../services/cloudinary_service.dart';
import 'gem_gallery_page.dart';
import 'package:just_audio/just_audio.dart';
import 'ai_music_page.dart';
import 'ai_music_magic_page.dart';

// Helper classes for animations and UI
class _TrashFly {
  final Offset baseOffset;
  final double phase;

  _TrashFly({
    required this.baseOffset,
    required this.phase,
  });
}

class _TrashFume {
  final Offset baseOffset;
  final double phase;

  _TrashFume({
    required this.baseOffset,
    required this.phase,
  });
}

class _CrystalShard {
  final double angle;
  final double speed;
  final Color color;
  final double rotationSpeed;
  final double size;
  late Offset position;
  late double rotation;

  _CrystalShard({
    required this.angle,
    required this.speed,
    required this.color,
    required this.rotationSpeed,
    required this.size,
  }) {
    position = Offset.zero;
    rotation = 0;
  }

  void update(double progress) {
    final distance = speed * progress;
    position = Offset(
      math.cos(angle) * distance,
      math.sin(angle) * distance,
    );
    rotation = rotationSpeed * progress * math.pi * 2;
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.5;
    
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HexagonClipper oldClipper) => false;
}

class _NavigationHexagonPainter extends CustomPainter {
  final double progress;
  final String? hoveredEdge;

  _NavigationHexagonPainter({
    required this.progress,
    required this.hoveredEdge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.48;
    
    // Draw background hexagon
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
          ruby.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    final path = Path();
    final points = <Offset>[];
    
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      points.add(point);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, bgPaint);

    // Draw edge segments with hover effects
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final directions = ['up', 'topRight', 'bottomRight', 'down', 'bottomLeft', 'topLeft'];
    
    for (int i = 0; i < 6; i++) {
      final start = points[i];
      final end = points[(i + 1) % 6];
      final direction = directions[i];
      
      final isHovered = hoveredEdge == direction;
      edgePaint.shader = LinearGradient(
        colors: [
          isHovered ? amethyst : amethyst.withOpacity(0.3),
          isHovered ? sapphire : sapphire.withOpacity(0.3),
        ],
        begin: Alignment(start.dx / size.width, start.dy / size.height),
        end: Alignment(end.dx / size.width, end.dy / size.height),
      ).createShader(Offset.zero & size);

      canvas.drawLine(start, end, edgePaint);
    }
  }

  @override
  bool shouldRepaint(_NavigationHexagonPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.hoveredEdge != hoveredEdge;
  }
}

class _CrystalShatterPainter extends CustomPainter {
  final double progress;
  final List<_CrystalShard> shards;

  _CrystalShatterPainter({
    required this.progress,
    required this.shards,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Update and draw each shard
    for (var shard in shards) {
      shard.update(progress);
      
      final paint = Paint()
        ..color = shard.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        center.dx + shard.position.dx,
        center.dy + shard.position.dy,
      );
      canvas.rotate(shard.rotation);

      // Draw crystal shard
      final path = Path();
      path.moveTo(-shard.size / 2, -shard.size / 2);
      path.lineTo(shard.size / 2, -shard.size / 2);
      path.lineTo(0, shard.size / 2);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // Draw fade out overlay
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = deepCave.withOpacity(progress * 0.8)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CrystalShatterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class GemExplorerPage extends StatefulWidget {
  final File recordedVideo;
  final String? cloudinaryUrl;  // Optional for now as we transition
  final String? gemId;  // ID of the current gem being edited

  const GemExplorerPage({
    super.key,
    required this.recordedVideo,
    this.cloudinaryUrl,  // Make it optional for backward compatibility
    this.gemId,
  });

  @override
  State<GemExplorerPage> createState() => _GemExplorerPageState();
}

class _GemExplorerPageState extends State<GemExplorerPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _shimmerController;
  final GemService _gemService = GemService();
  final _audioPlayer = AudioPlayer();
  String? _errorMessage;
  bool _isPlaying = false;
  bool _isMuted = false;  // Add mute state
  
  // Track current position and content
  Offset _currentOffset = Offset.zero;
  
  // Animation controllers for transitions
  Animation<Offset>? _slideAnimation;
  AnimationController? _slideController;
  
  // Track current path and position
  int _currentDepth = 0;
  List<String> _currentPath = ['origin'];
  
  // Content grid - key is "x,y" coordinate
  final Map<String, Map<String, dynamic>> _contentGrid = {};
  
  // Track hover state for navigation edges
  String? _hoveredEdge;
  
  // Store Cloudinary URL
  String? get cloudinaryUrl => widget.cloudinaryUrl;
  
  // Mystical content for exploration
  final List<Map<String, dynamic>> _editOptions = [
    {'type': 'edit', 'content': '🔮', 'name': 'AI Music Magic', 'description': 'Generate magical music', 'direction': 'topLeft'},
    {'type': 'edit', 'content': '✨', 'name': 'Enhance', 'description': 'Improve video quality', 'direction': 'topRight'},
    {'type': 'edit', 'content': '🎵', 'name': 'AI Music', 'description': 'Generate background music', 'direction': 'right'},
    {'type': 'edit', 'content': '⚡', 'name': 'Effects', 'description': 'Add visual effects', 'direction': 'bottomRight'},
    {'type': 'edit', 'content': '✂️', 'name': 'Trim', 'description': 'Edit video length', 'direction': 'bottomLeft'},
    {'type': 'edit', 'content': '🔄', 'name': 'Transform', 'description': 'Rotate or flip', 'direction': 'left'},
  ];

  // Navigation directions with their offsets and angles
  final Map<String, Map<String, dynamic>> _directions = {
    'up': {'offset': const Offset(0, -1), 'angle': -math.pi / 2},
    'down': {'offset': const Offset(0, 1), 'angle': math.pi / 2},
    'right': {'offset': const Offset(1, 0), 'angle': 0},
    'left': {'offset': const Offset(-1, 0), 'angle': math.pi},
    'topRight': {'offset': const Offset(1, -0.5), 'angle': -math.pi / 3},     // Content slides down-left
    'topLeft': {'offset': const Offset(-1, -0.5), 'angle': -2 * math.pi / 3}, // Content slides down-right
    'bottomRight': {'offset': const Offset(1, 0.5), 'angle': math.pi / 3},    // Content slides up-left
    'bottomLeft': {'offset': const Offset(-1, 0.5), 'angle': 2 * math.pi / 3},// Content slides up-right
  };

  late AnimationController _trashWobbleController;
  late AnimationController _flyController;
  late AnimationController _fumeController;
  final List<_TrashFly> _flies = [];
  final List<_TrashFume> _fumes = [];

  late AnimationController _shatterController;
  final List<_CrystalShard> _shards = [];
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    print('Initializing video from path: ${widget.recordedVideo.path}');
    if (cloudinaryUrl != null) {
      print('Cloudinary URL available: $cloudinaryUrl');
      _videoController = VideoPlayerController.network(cloudinaryUrl!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              print('Video dimensions: ${_videoController.value.size}');
              print('Video aspect ratio: ${_videoController.value.aspectRatio}');
              _videoController.play();
              _videoController.setLooping(true);
              _videoController.setVolume(1.0);  // Set initial volume
              print('Video initialized and playing');
            });
          }
        }).catchError((error) {
          print('Error initializing video: $error');
          setState(() => _errorMessage = 'Failed to load video: $error');
        });
    } else {
      _videoController = VideoPlayerController.file(widget.recordedVideo)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              print('Video dimensions: ${_videoController.value.size}');
              print('Video aspect ratio: ${_videoController.value.aspectRatio}');
              _videoController.play();
              _videoController.setLooping(true);
              _videoController.setVolume(1.0);  // Set initial volume
              print('Video initialized and playing');
            });
          }
        }).catchError((error) {
          print('Error initializing video: $error');
          setState(() => _errorMessage = 'Failed to load video: $error');
        });
    }

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Initialize content grid with video at center
    _contentGrid['0,0'] = {
      'type': 'video',
      'content': widget.recordedVideo,
      'cloudinaryUrl': cloudinaryUrl,
    };
    _generateSurroundingContent(const Offset(0, 0));

    // Initialize trash animation controllers
    _trashWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fumeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Create flies with random positions
    for (int i = 0; i < 3; i++) {
      _flies.add(_TrashFly(
        baseOffset: Offset(
          math.Random().nextDouble() * 20 - 10,
          math.Random().nextDouble() * 20 - 10,
        ),
        phase: math.Random().nextDouble() * math.pi * 2,
      ));
    }

    // Create fumes with random properties
    for (int i = 0; i < 4; i++) {
      _fumes.add(_TrashFume(
        baseOffset: Offset(
          math.Random().nextDouble() * 16 - 8,
          -10 - math.Random().nextDouble() * 10,
        ),
        phase: math.Random().nextDouble() * math.pi * 2,
      ));
    }

    _shatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Generate crystal shards for deletion animation
    for (int i = 0; i < 12; i++) {
      _shards.add(_CrystalShard(
        angle: i * (math.pi * 2 / 12),
        speed: 100 + math.Random().nextDouble() * 200,
        color: [emerald, amethyst, sapphire, ruby][math.Random().nextInt(4)],
        rotationSpeed: math.Random().nextDouble() * 4 - 2,
        size: 10 + math.Random().nextDouble() * 20,
      ));
    }

    // Initialize audio player
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setAsset('assets/audio/crystal_delete.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);  // Loop the audio
      await _audioPlayer.setVolume(1.0);  // Set volume to 62.5% (25% louder than before)
    } catch (e) {
      print('❌ Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _shimmerController.dispose();
    _slideController?.dispose();
    _trashWobbleController.dispose();
    _flyController.dispose();
    _fumeController.dispose();
    _shatterController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Handles spatial navigation in the gem explorer grid
  // direction: The direction to move (e.g., 'up', 'topRight', etc.)
  // Creates a slide animation and updates the content grid
  Future<void> _navigate(String direction) async {
    if (_slideController?.isAnimating ?? false) return;
    
    HapticFeedback.mediumImpact();
    
    final directionData = _directions[direction]!;
    final targetOffset = _currentOffset + (directionData['offset'] as Offset);
    
    // Create and start slide animation
    _slideController?.dispose();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Reverse the animation direction to create the feeling of moving towards the clicked direction
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: directionData['offset'] as Offset, // Removed the negative sign to reverse direction
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeInOutQuart,
    ));

    setState(() {
      _currentPath.add('path_${_currentDepth}_$direction');
      _currentDepth++;
    });

    _generateSurroundingContent(targetOffset);
    
    await _slideController!.forward();
    setState(() {
      _currentOffset = targetOffset;
      _hoveredEdge = null;
    });
    _slideController!.reset();
  }

  // Builds a tile in the gem grid - either a video tile or an edit option tile
  // content: Map containing tile data (type, content, etc.)
  // isCenter: Whether this tile is in the center of the grid
  Widget _buildGemTile({required Map<String, dynamic> content, bool isCenter = false}) {
    final size = MediaQuery.of(context).size;
    final tileSize = size.width * (isCenter ? 0.3 : 0.25);

    if (content['type'] == 'video') {
      return Container(
        width: tileSize,
        height: tileSize,
        margin: EdgeInsets.all(size.width * 0.01),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tileSize / 6),
          border: Border.all(
            color: content['isEdited'] == true 
              ? amethyst.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
            width: content['isEdited'] == true ? 2 : 1,
          ),
          boxShadow: content['isEdited'] == true ? [
            BoxShadow(
              color: amethyst.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: sapphire.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildVideoContent(content),
      );
    }

    // Edit option tiles
    return GestureDetector(
      onTap: () => _handleEditOption(content),
      child: Container(
        width: tileSize,
        height: tileSize,
        margin: EdgeInsets.all(size.width * 0.01),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tileSize / 6),
          border: Border.all(
            color: amethyst.withOpacity(0.3),
            width: 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              deepCave.withOpacity(0.8),
              caveShadow.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              content['content'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              content['name'],
              style: gemText.copyWith(
                color: silver,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Handles the selection of an edit option (like trim, effects, etc.)
  void _handleEditOption(Map<String, dynamic> option) async {
    HapticFeedback.mediumImpact();
    
    // Get the direction directly from the option
    final direction = option['direction'] as String;
    
    print('Selected edit option: ${option['name']} (moving ${option['direction']})');
    
    // First, perform the spatial navigation
    await _navigate(direction);
    
    // Handle different edit options
    if (option['name'] == 'Trim') {
      // Add a slight delay to ensure navigation is complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get the current video URL directly from the video controller
      final videoUrlToEdit = _videoController.dataSource;
      if (videoUrlToEdit == null) {
        print('Error: No video URL available from controller');
        return;
      }
      
      print('Opening crop view with video URL: $videoUrlToEdit');
      
      // Show the crystal lens cropper with glass effect overlay
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Crop View',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Glass effect background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: deepCave.withOpacity(0.5),
                  ),
                ),
              ),
              
              // Crop page with fade transition
              FadeTransition(
                opacity: animation,
                child: VideoCropPage(
                  videoUrl: videoUrlToEdit,
                  sourceGemId: widget.gemId,
                  onCropComplete: (String newVideoUrl) {
                    // Update the content grid with the new video
                    final key = '${_currentOffset.dx.toInt()},${_currentOffset.dy.toInt()}';
                    setState(() {
                      _contentGrid[key] = {
                        'type': 'video',
                        'content': widget.recordedVideo,
                        'cloudinaryUrl': newVideoUrl,
                        'isEdited': true,
                      };
                    });
                  },
                ),
              ),
            ],
          );
        },
      );
    } else if (option['name'] == 'AI Music Magic') {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final videoUrlToEdit = _videoController.dataSource;
      if (videoUrlToEdit == null) {
        print('Error: No video URL available from controller');
        return;
      }
      
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'AI Music Magic',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Glass effect background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: deepCave.withOpacity(0.5),
                  ),
                ),
              ),
              
              // AI Music Magic page with fade transition
              FadeTransition(
                opacity: animation,
                child: AIMusicMagicPage(
                  videoPath: widget.recordedVideo.path,
                  videoController: _videoController,
                ),
              ),
            ],
          );
        },
      );
    } else if (option['name'] == 'AI Music') {
      // Add a slight delay to ensure navigation is complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Show the AI Music page with glass effect overlay
      final result = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'AI Music',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Glass effect background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: deepCave.withOpacity(0.5),
                  ),
                ),
              ),
              
              // AI Music page with fade transition
              FadeTransition(
                opacity: animation,
                child: AIMusicPage(
                  videoPath: widget.recordedVideo.path,
                  videoController: _videoController,
                ),
              ),
            ],
          );
        },
      );

      if (result != null) {
        // User accepted the generated music
        print('Generated music URL: $result');
        // TODO: Handle the accepted music URL
        // We'll implement Cloudinary integration later
      }
    }
  }

  // Creates a hexagonal grid layout with the video in the center
  // surrounded by edit options in a crystal-like pattern
  Widget _buildHexagonalGrid() {
    // Get edit options for surrounding tiles in the correct positions
    final topLeft = _editOptions[0];     // Style Transfer
    final topRight = _editOptions[1];    // Enhance
    final right = _editOptions[2];       // AI Music
    final bottomRight = _editOptions[3]; // Effects
    final bottomLeft = _editOptions[4];  // Trim
    final left = _editOptions[5];        // Transform

    // Center content is always the video
    final centerContent = {
      'type': 'video',
      'content': widget.recordedVideo,
      'cloudinaryUrl': cloudinaryUrl,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top row
              Padding(
                padding: EdgeInsets.only(bottom: constraints.maxWidth * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGemTile(content: topLeft),    // Style Transfer (top-left)
                    SizedBox(width: constraints.maxWidth * 0.02),
                    _buildGemTile(content: topRight),   // Enhance (top-right)
                  ],
                ),
              ),
              // Middle row (with center tile)
              Padding(
                padding: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGemTile(content: left),       // Transform (left)
                    SizedBox(width: constraints.maxWidth * 0.02),
                    _buildGemTile(content: centerContent, isCenter: true),
                    SizedBox(width: constraints.maxWidth * 0.02),
                    _buildGemTile(content: right),      // AI Music (right)
                  ],
                ),
              ),
              // Bottom row
              Padding(
                padding: EdgeInsets.only(top: constraints.maxWidth * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGemTile(content: bottomLeft), // Trim (bottom-left)
                    SizedBox(width: constraints.maxWidth * 0.02),
                    _buildGemTile(content: bottomRight),// Effects (bottom-right)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Displays video content within a tile with play/pause controls
  // and loading states
  Widget _buildVideoContent(Map<String, dynamic> content) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_videoController.value.isInitialized) 
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        if (!_videoController.value.isPlaying)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
      ],
    );
  }

  // Generates surrounding content tiles based on the current position
  // Ensures there are always options available in each direction
  void _generateSurroundingContent(Offset center) {
    _directions.forEach((direction, data) {
      final offset = center + (data['offset'] as Offset);
      final key = '${offset.dx.toInt()},${offset.dy.toInt()}';
      if (!_contentGrid.containsKey(key)) {
        _contentGrid[key] = _editOptions[math.Random().nextInt(_editOptions.length)];
      }
    });
  }

  Widget _buildTrashButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTapDown: (_) {
          _trashWobbleController.forward(from: 0);
          HapticFeedback.mediumImpact();
        },
        onTapUp: (_) async {
          // Show delete confirmation dialog
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Delete Confirmation',
            barrierColor: deepCave.withOpacity(0.8),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              // Start playing the audio
              _audioPlayer.play();
              
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: caveShadow.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(emeraldCut),
                    border: Border.all(
                      color: ruby.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ruby.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated trash icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: ruby.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ruby.withOpacity(0.3),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Reuse our animated flies and fumes here
                            ...List.generate(_fumes.length, (index) {
                              return AnimatedBuilder(
                                animation: _fumeController,
                                builder: (context, child) {
                                  final fume = _fumes[index];
                                  final progress = _fumeController.value;
                                  final yOffset = fume.baseOffset.dy - (progress * 20);
                                  final xOffset = fume.baseOffset.dx + 
                                    math.sin(progress * math.pi * 2 + fume.phase) * 4;
                                  return Positioned(
                                    left: 30 + xOffset,
                                    top: 30 + yOffset,
                                    child: Transform.scale(
                                      scale: 0.8 + progress * 0.4,
                                      child: Opacity(
                                        opacity: (1 - progress) * 0.6,
                                        child: Text(
                                          '~',
                                          style: TextStyle(
                                            color: ruby.withOpacity(0.6),
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            Center(
                              child: Icon(
                                Icons.delete_forever,
                                color: ruby.withOpacity(0.8),
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Are you sure you want to delete this gem?',
                        style: crystalHeading.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This action cannot be undone!',
                        style: gemText.copyWith(
                          color: ruby,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: sapphire.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(emeraldCut),
                                side: BorderSide(
                                  color: sapphire.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Cancel '),
                                const Text('😱', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                          // Delete button
                          TextButton(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop(true);
                              await _deleteGem();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: ruby.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(emeraldCut),
                                side: BorderSide(
                                  color: ruby.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Delete '),
                                const Text('😈', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ).then((_) {
            // Stop the audio when dialog is closed
            _audioPlayer.stop();
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ruby.withOpacity(0.1),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: ruby.withOpacity(0.3),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Fumes
              ...List.generate(_fumes.length, (index) {
                return AnimatedBuilder(
                  animation: _fumeController,
                  builder: (context, child) {
                    final fume = _fumes[index];
                    final progress = _fumeController.value;
                    final yOffset = fume.baseOffset.dy - (progress * 20);
                    final xOffset = fume.baseOffset.dx + 
                      math.sin(progress * math.pi * 2 + fume.phase) * 4;
                    final opacity = (1 - progress) * 0.6;

                    return Positioned(
                      left: 20 + xOffset,
                      top: 20 + yOffset,
                      child: Transform.scale(
                        scale: 0.8 + progress * 0.4,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            '~',
                            style: TextStyle(
                              color: ruby.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Flies
              ...List.generate(_flies.length, (index) {
                return AnimatedBuilder(
                  animation: _flyController,
                  builder: (context, child) {
                    final fly = _flies[index];
                    final progress = _flyController.value;
                    final xOffset = fly.baseOffset.dx + 
                      math.sin(progress * math.pi * 4 + fly.phase) * 8;
                    final yOffset = fly.baseOffset.dy + 
                      math.cos(progress * math.pi * 2 + fly.phase) * 6;

                    return Positioned(
                      left: 20 + xOffset,
                      top: 20 + yOffset,
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: ruby.withOpacity(0.8),
                          fontSize: 8,
                        ),
                      ),
                    );
                  },
                );
              }),

              // Trash can
              Center(
                child: AnimatedBuilder(
                  animation: _trashWobbleController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_trashWobbleController.value * math.pi * 2) * 0.1,
                      child: Icon(
                        Icons.delete_forever,
                        color: ruby.withOpacity(0.8),
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add method to toggle mute state
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController.setVolume(_isMuted ? 0.0 : 1.0);
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_videoController.value.isInitialized) {
      return _buildLoadingScreen();
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: deepCave,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              'Gem Explorer',
              style: crystalHeading.copyWith(fontSize: 20),
            ),
            actions: [
              // Add mute button
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: _isMuted ? ruby : emerald,
                ),
                onPressed: _toggleMute,
              ),
              _buildTrashButton(),
              if (widget.gemId != null) // Only show edit button for existing gems
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit, color: emerald, size: 20),
                    label: Text(
                      'Edit Meta',
                      style: gemText.copyWith(
                        color: emerald,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () async {
                      final gem = await _gemService.getGem(widget.gemId!);
                      if (gem != null && mounted) {
                        final result = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => 
                              GemMetaEditPage(
                                gemId: widget.gemId!,
                                gem: gem,
                              ),
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
                        
                        // Refresh the page if changes were made
                        if (result == true) {
                          setState(() {});
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: emerald.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        side: BorderSide(
                          color: emerald.withOpacity(0.3),
                        ),
                      ),
                    ),
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
          ),
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main content with animations
                Center(
                  child: AnimatedBuilder(
                    animation: _slideController ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      final slideOffset = _slideAnimation?.value ?? Offset.zero;
                      return Transform.translate(
                        offset: Offset(
                          slideOffset.dx * MediaQuery.of(context).size.width * 0.5,
                          slideOffset.dy * MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: _buildHexagonalGrid(),
                      );
                    },
                  ),
                ),

                // Path indicator
                Positioned(
                  top: 16,
                  left: 16,
                  child: Text(
                    _currentPath.join(' → '),
                    style: gemText.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),

                // Publish button
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: GemButton(
                    text: '✨ Share Your Gem',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublishGemPage(
                            cloudinaryUrl: cloudinaryUrl!,
                          ),
                        ),
                      );
                    },
                    gemColor: amethyst,
                    isAnimated: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isDeleting)
          AnimatedBuilder(
            animation: _shatterController,
            builder: (context, child) {
              return CustomPaint(
                painter: _CrystalShatterPainter(
                  progress: _shatterController.value,
                  shards: _shards,
                ),
                size: Size.infinite,
              );
            },
          ),
      ],
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
              text: 'Go Back',
              onPressed: () => Navigator.pop(context),
              gemColor: emerald,
              isAnimated: true,
            ),
            if (widget.gemId != null) ...[
              const SizedBox(height: 32),
              // Animated trash can for deletion
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: deepCave,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        side: BorderSide(color: ruby.withOpacity(0.3)),
                      ),
                      title: Text(
                        'Delete Broken Gem?',
                        style: crystalHeading.copyWith(color: ruby),
                        textAlign: TextAlign.center,
                      ),
                      content: Text(
                        'This video appears to be broken or missing. Would you like to remove it from your collection?',
                        style: gemText.copyWith(color: silver),
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: gemText.copyWith(color: silver)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: gemText.copyWith(color: ruby)),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    await _deleteGem();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ruby.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ruby.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Reuse our animated flies and fumes here
                      ...List.generate(_fumes.length, (index) {
                        return AnimatedBuilder(
                          animation: _fumeController,
                          builder: (context, child) {
                            final fume = _fumes[index];
                            final progress = _fumeController.value;
                            final yOffset = fume.baseOffset.dy - (progress * 20);
                            final xOffset = fume.baseOffset.dx + 
                              math.sin(progress * math.pi * 2 + fume.phase) * 4;
                            return Positioned(
                              left: 40 + xOffset,
                              top: 40 + yOffset,
                              child: Transform.scale(
                                scale: 0.8 + progress * 0.4,
                                child: Opacity(
                                  opacity: (1 - progress) * 0.6,
                                  child: Text(
                                    '~',
                                    style: TextStyle(
                                      color: ruby.withOpacity(0.6),
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      Center(
                        child: AnimatedBuilder(
                          animation: _trashWobbleController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: math.sin(_trashWobbleController.value * math.pi * 2) * 0.1,
                              child: Icon(
                                Icons.delete_forever,
                                color: ruby.withOpacity(0.8),
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to delete broken video',
                style: gemText.copyWith(
                  color: ruby.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: gemText.copyWith(color: silver),
            ),
          ],
        ),
      ),
    );
  }

  // Delete the gem from both device and cloud
  Future<void> _deleteGem() async {
    if (widget.gemId == null) {
      print('❌ No gem ID provided for deletion');
      return;
    }

    setState(() => _isDeleting = true);

    try {
      // Show loading overlay with crystal animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,  // Prevent back button
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: deepCave.withOpacity(0.95),
                borderRadius: BorderRadius.circular(emeraldCut),
                border: Border.all(
                  color: ruby.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ruby.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated crystal shard
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        // Rotating outer glow
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _shimmerController.value * 2 * math.pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      ruby.withOpacity(0.5),
                                      amethyst.withOpacity(0.5),
                                      sapphire.withOpacity(0.5),
                                      ruby.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Center crystal
                        Center(
                          child: Icon(
                            Icons.diamond_outlined,
                            color: ruby.withOpacity(0.8),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Shattering Crystal...',
                    style: crystalHeading.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your gem is being carefully removed',
                    style: gemText.copyWith(
                      color: silver,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Start the shattering animation
      _shatterController.forward(from: 0);
      
      // Get the gem data before deletion
      final gem = await _gemService.getGem(widget.gemId!);
      if (gem == null) throw Exception('Gem not found');

      // Delete from Firestore first
      await _gemService.deleteGem(widget.gemId!);
      print('✨ Deleted gem from Firestore');

      // Delete from Cloudinary if URL exists
      if (gem.cloudinaryPublicId != null) {
        final cloudinaryService = CloudinaryService();
        await cloudinaryService.deleteVideo(gem.cloudinaryPublicId);
        print('✨ Deleted video from Cloudinary');
      }

      // Delete local file if it exists
      if (widget.recordedVideo.existsSync()) {
        await widget.recordedVideo.delete();
        print('✨ Deleted local video file');
      }

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();
        
        // Navigate back to gallery
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
      }
    } catch (e) {
      print('❌ Error deleting gem: $e');
      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete gem: $e',
              style: gemText.copyWith(color: Colors.white),
            ),
            backgroundColor: ruby.withOpacity(0.8),
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }
} 