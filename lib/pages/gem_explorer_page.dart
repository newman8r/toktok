import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:math' as math;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'publish_gem_page.dart';

class GemExplorerPage extends StatefulWidget {
  final File recordedVideo;
  final String? cloudinaryUrl;  // Optional for now as we transition

  const GemExplorerPage({
    super.key,
    required this.recordedVideo,
    this.cloudinaryUrl,  // Make it optional for backward compatibility
  });

  @override
  State<GemExplorerPage> createState() => _GemExplorerPageState();
}

class _GemExplorerPageState extends State<GemExplorerPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _shimmerController;
  String? _errorMessage;
  bool _isPlaying = false;
  
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
    {'type': 'edit', 'content': '🎨', 'name': 'Style Transfer', 'description': 'Apply artistic styles', 'direction': 'topLeft'},
    {'type': 'edit', 'content': '✨', 'name': 'Enhance', 'description': 'Improve video quality', 'direction': 'topRight'},
    {'type': 'edit', 'content': '🎵', 'name': 'Audio', 'description': 'Add or modify audio', 'direction': 'right'},
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
  }

  @override
  void dispose() {
    _videoController.dispose();
    _shimmerController.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  void _generateSurroundingContent(Offset center) {
    _directions.forEach((direction, data) {
      final offset = center + (data['offset'] as Offset);
      final key = '${offset.dx.toInt()},${offset.dy.toInt()}';
      if (!_contentGrid.containsKey(key)) {
        _contentGrid[key] = _editOptions[math.Random().nextInt(_editOptions.length)];
      }
    });
  }

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
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
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

  void _handleEditOption(Map<String, dynamic> option) {
    HapticFeedback.mediumImpact();
    
    // Get the direction directly from the option
    final direction = option['direction'] as String;
    
    print('Selected edit option: ${option['name']} (moving ${option['direction']})');
    _navigate(direction);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_videoController.value.isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: deepCave,
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
    );
  }

  Widget _buildHexagonalGrid() {
    // Get edit options for surrounding tiles in the correct positions
    final topLeft = _editOptions[0];     // Style Transfer
    final topRight = _editOptions[1];    // Enhance
    final right = _editOptions[2];       // Audio
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
                    _buildGemTile(content: right),      // Audio (right)
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