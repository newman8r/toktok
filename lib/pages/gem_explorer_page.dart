import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:math' as math;
import '../theme/gem_theme.dart';

class GemExplorerPage extends StatefulWidget {
  final File recordedVideo;

  const GemExplorerPage({
    super.key,
    required this.recordedVideo,
  });

  @override
  State<GemExplorerPage> createState() => _GemExplorerPageState();
}

class _GemExplorerPageState extends State<GemExplorerPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _shimmerController;
  
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
  
  // Mystical content for exploration
  final List<Map<String, dynamic>> _mysticalContent = [
    {'type': 'emoji', 'content': '💎'},
    {'type': 'emoji', 'content': '🔮'},
    {'type': 'emoji', 'content': '✨'},
    {'type': 'emoji', 'content': '🌟'},
    {'type': 'emoji', 'content': '🌌'},
    {'type': 'emoji', 'content': '💫'},
    {'type': 'emoji', 'content': '⭐'},
    {'type': 'emoji', 'content': '🌠'},
  ];

  // Navigation directions with their offsets and angles
  final Map<String, Map<String, dynamic>> _directions = {
    'up': {'offset': const Offset(0, -1), 'angle': -math.pi / 2},
    'down': {'offset': const Offset(0, 1), 'angle': math.pi / 2},
    'topRight': {'offset': const Offset(1, -0.5), 'angle': -math.pi / 3},
    'topLeft': {'offset': const Offset(-1, -0.5), 'angle': -2 * math.pi / 3},
    'bottomRight': {'offset': const Offset(1, 0.5), 'angle': math.pi / 3},
    'bottomLeft': {'offset': const Offset(-1, 0.5), 'angle': 2 * math.pi / 3},
  };

  @override
  void initState() {
    super.initState();
    print('Initializing video from path: ${widget.recordedVideo.path}');
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
      });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Initialize content grid with video at center
    _contentGrid['0,0'] = {'type': 'video', 'content': widget.recordedVideo};
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
        _contentGrid[key] = _mysticalContent[math.Random().nextInt(_mysticalContent.length)];
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

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: -directionData['offset'] as Offset,
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
    final tileSize = size.width * (isCenter ? 0.4 : 0.3);

    return Container(
      width: tileSize,
      height: tileSize,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCenter ? amethyst.withOpacity(0.3) : caveShadow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: isCenter ? amethyst.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCenter ? amethyst.withOpacity(0.2) : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (content['type'] == 'video') {
              if (_videoController.value.isPlaying) {
                _videoController.pause();
              } else {
                _videoController.play();
              }
              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(emeraldCut),
          child: ClipPath(
            clipper: _HexagonClipper(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _buildContent(content, isCenter),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> content, bool isCenter) {
    if (content['type'] == 'video') {
      return Stack(
        alignment: Alignment.center,
        children: [
          if (_videoController.value.isInitialized) 
            Container(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.contain,
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
    } else {
      return Text(
        content['content'],
        style: const TextStyle(fontSize: 32),
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Navigation hexagon background
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Convert touch position to angle from center
                  final size = MediaQuery.of(context).size;
                  final center = Offset(size.width / 2, size.height / 2);
                  final touchPosition = details.localPosition;
                  final angle = (touchPosition - center).direction;
                  
                  // Map angle to direction
                  String? direction;
                  if (angle > -math.pi/6 && angle <= math.pi/6) direction = 'topRight';
                  else if (angle > math.pi/6 && angle <= math.pi/2) direction = 'bottomRight';
                  else if (angle > math.pi/2 && angle <= 5*math.pi/6) direction = 'down';
                  else if (angle > 5*math.pi/6 || angle <= -5*math.pi/6) direction = 'bottomLeft';
                  else if (angle > -5*math.pi/6 && angle <= -math.pi/2) direction = 'down';
                  else if (angle > -math.pi/2 && angle <= -math.pi/6) direction = 'topLeft';
                  
                  setState(() => _hoveredEdge = direction);
                },
                onPanEnd: (_) {
                  if (_hoveredEdge != null) {
                    _navigate(_hoveredEdge!);
                    _hoveredEdge = null;
                  }
                },
                child: CustomPaint(
                  painter: _NavigationHexagonPainter(
                    progress: _shimmerController.value,
                    hoveredEdge: _hoveredEdge,
                  ),
                ),
              ),
            ),

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
                    child: _buildHexagonalGrid(
                      centerContent: _contentGrid['${_currentOffset.dx.toInt()},${_currentOffset.dy.toInt()}'] ?? 
                        {'type': 'video', 'content': widget.recordedVideo},
                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHexagonalGrid({required Map<String, dynamic> centerContent}) {
    // Get surrounding content based on current position
    final topLeft = _contentGrid['${_currentOffset.dx - 1},${_currentOffset.dy - 0.5}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(-1, -0.5));
    final topRight = _contentGrid['${_currentOffset.dx + 1},${_currentOffset.dy - 0.5}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(1, -0.5));
    final left = _contentGrid['${_currentOffset.dx - 1},${_currentOffset.dy}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(-1, 0));
    final right = _contentGrid['${_currentOffset.dx + 1},${_currentOffset.dy}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(1, 0));
    final bottomLeft = _contentGrid['${_currentOffset.dx - 1},${_currentOffset.dy + 0.5}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(-1, 0.5));
    final bottomRight = _contentGrid['${_currentOffset.dx + 1},${_currentOffset.dy + 0.5}'] ?? 
      _generateAndStoreContent(_currentOffset + const Offset(1, 0.5));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGemTile(content: topLeft),
              _buildGemTile(content: topRight),
            ],
          ),
          // Middle row (with center tile)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGemTile(content: left),
              _buildGemTile(content: centerContent, isCenter: true),
              _buildGemTile(content: right),
            ],
          ),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGemTile(content: bottomLeft),
              _buildGemTile(content: bottomRight),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateAndStoreContent(Offset position) {
    final key = '${position.dx},${position.dy}';
    if (!_contentGrid.containsKey(key)) {
      _contentGrid[key] = _mysticalContent[math.Random().nextInt(_mysticalContent.length)];
    }
    return _contentGrid[key]!;
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