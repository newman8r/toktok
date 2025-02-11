import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/gem_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../services/contextual_music_service.dart';
import '../services/openai_service.dart';

class AIMusicMagicPage extends StatefulWidget {
  final String videoPath;
  final VideoPlayerController videoController;

  const AIMusicMagicPage({
    super.key,
    required this.videoPath,
    required this.videoController,
  });

  @override
  State<AIMusicMagicPage> createState() => _AIMusicMagicPageState();
}

class _AIMusicMagicPageState extends State<AIMusicMagicPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _crystalBallController;
  bool _isMagicStarted = false;
  final ContextualMusicService _contextService = ContextualMusicService();
  final OpenAIService _openAIService = OpenAIService();
  String? _errorMessage;
  String? _generatedLyrics;

  @override
  void initState() {
    super.initState();
    _crystalBallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  Future<void> _startMagic() async {
    try {
      setState(() {
        _isMagicStarted = true;
        _errorMessage = null;
        _generatedLyrics = null;
      });
      
      print('🔮 Starting Crystal Magic...');
      HapticFeedback.mediumImpact();

      // Get unified context
      print('🌍 Gathering mystical energies from your surroundings...');
      final context = await _contextService.getUnifiedContext();
      
      // Log the gathered context
      print('\n✨ Magical Context Gathered ✨');
      print('🌤️  Weather: ${context.weather.description}');
      print('🌡️  Temperature: ${context.weather.temperature}°C');
      print('🌅 Time of Day: ${context.weather.timeOfDay}');
      print('🎭 Weather Mood: ${context.weather.mood}');
      
      print('\n📍 Location Vibes:');
      print('🏢 Place: ${context.location.locationName}');
      print('🌟 Vibe Words: ${context.location.vibeWords.join(", ")}');
      print('🎵 Ambiance: ${context.location.ambiance}');
      print('👥 Crowd Level: ${context.location.crowdLevel}');
      
      print('\n📅 Time Context:');
      print('📆 ${context.calendar.dayOfWeek}, ${context.calendar.month} ${context.calendar.dayOfMonth}');
      print('🍂 Season: ${context.calendar.season}');
      print('⏰ Time: ${context.calendar.timeOfDay}');
      
      print('\n🎼 Musical Inspiration:');
      print('🎵 Suggested Style: ${context.determineMusicStyle()}');
      print('✍️ Lyrical Theme: ${context.generateLyricalTheme()}');

      // Generate lyrics with OpenAI
      final locationVibe = '${context.location.ambiance} ${context.location.vibeWords.join(" ")}';
      final timeContext = '${context.calendar.timeOfDay} in ${context.calendar.season}';
      
      _generatedLyrics = await _openAIService.generateLyrics(
        musicStyle: context.determineMusicStyle(),
        weatherMood: context.weather.mood,
        timeContext: timeContext,
        locationVibe: locationVibe,
        temperature: context.weather.temperature.toString(),
        weatherDescription: context.weather.description,
      );
      
      // TODO: In the next step, we'll use these lyrics with Uberduck!
      
    } catch (e) {
      print('❌ Error during magic gathering: $e');
      setState(() {
        _errorMessage = 'Failed to gather magical context: $e';
        _isMagicStarted = false;
      });
    }
  }

  @override
  void dispose() {
    _crystalBallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '✨ Crystal Soundscape',
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
                    amethyst.withOpacity(0.15),
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
          // Crystal background effect
          CustomPaint(
            painter: _CrystalBackgroundPainter(
              progress: _crystalBallController.value,
            ),
            size: Size.infinite,
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Video preview
                    AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        child: VideoPlayer(widget.videoController),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                    // Crystal ball and magic button
                    if (!_isMagicStarted) ...[
                      _buildCrystalBall(),
                      const SizedBox(height: 48),
                      _buildMagicButton(),
                      const SizedBox(height: 48),
                    ] else ...[
                      _buildLoadingAnimation(),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalBall() {
    return AnimatedBuilder(
      animation: _crystalBallController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                sapphire.withOpacity(0.3),
                amethyst.withOpacity(0.3),
              ],
              transform: GradientRotation(
                _crystalBallController.value * 2 * math.pi,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: sapphire.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: amethyst.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.white.withOpacity(
                0.5 + math.sin(_crystalBallController.value * math.pi * 2) * 0.3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagicButton() {
    return GestureDetector(
      onTapDown: (_) => _startMagic(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              amethyst.withOpacity(0.3),
              sapphire.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(emeraldCut),
          border: Border.all(
            color: amethyst.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: amethyst.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          'Begin Crystal Magic ✨',
          style: crystalHeading.copyWith(
            fontSize: 20,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _CrystalLoadingPainter(
              progress: _crystalBallController.value,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Channeling Crystal Energy...',
          style: gemText.copyWith(
            color: amethyst,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Creating your magical soundscape',
          style: gemText.copyWith(
            color: silver.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: gemText.copyWith(
              color: ruby,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _CrystalBackgroundPainter extends CustomPainter {
  final double progress;

  _CrystalBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + progress * math.pi * 2;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            sapphire.withOpacity(0.1),
            amethyst.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        ));

      final path = Path();
      path.moveTo(
        center.dx + math.cos(angle) * size.width * 0.2,
        center.dy + math.sin(angle) * size.height * 0.2,
      );
      path.lineTo(
        center.dx + math.cos(angle) * size.width,
        center.dy + math.sin(angle) * size.height,
      );
      path.lineTo(
        center.dx + math.cos(angle + math.pi / 6) * size.width * 0.8,
        center.dy + math.sin(angle + math.pi / 6) * size.height * 0.8,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrystalBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CrystalLoadingPainter extends CustomPainter {
  final double progress;

  _CrystalLoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + progress * math.pi * 2;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            amethyst.withOpacity(0.8),
            sapphire.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        ));

      final path = Path();
      path.moveTo(
        center.dx + math.cos(angle) * radius * 0.3,
        center.dy + math.sin(angle) * radius * 0.3,
      );
      path.lineTo(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      path.lineTo(
        center.dx + math.cos(angle + math.pi / 8) * radius * 0.8,
        center.dy + math.sin(angle + math.pi / 8) * radius * 0.8,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrystalLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 