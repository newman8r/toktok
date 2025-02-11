import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/gem_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../services/contextual_music_service.dart';
import '../services/openai_service.dart';
import '../services/uberduck_service.dart';
import 'package:just_audio/just_audio.dart';

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
  bool _isGeneratingLyrics = false;
  bool _isGeneratingMusic = false;
  final ContextualMusicService _contextService = ContextualMusicService();
  final OpenAIService _openAIService = OpenAIService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _errorMessage;
  String? _generatedLyrics;
  String? _generatedAudioUrl;
  bool _hasGenerated = false;
  String _selectedStyle = 'Modern';  // Default style

  // Style preset mapping between display names and API values
  final Map<String, String> _stylePresets = {
    'Abstract': 'Abstract',
    'Boom Bap': 'Boom Bap',
    'Cloud Rap': 'Cloud Rap',
    'Conscious': 'Conscious',
    'Drill': 'Drill',
    'East Coast': 'East Coast',
    'Grime': 'Grime',
    'Hardcore': 'Hardcore',
    'Lo-fi': 'Lo-fi',
    'Melodic': 'Melodic',
    'Modern': 'Modern',
    'Old School': 'Old School',
    'Party': 'Party',
    'Southern': 'Southern',
    'Underground': 'Underground',
    'West Coast': 'West Coast',
  };

  @override
  void initState() {
    super.initState();
    _crystalBallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _crystalBallController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startMagic() async {
    try {
      setState(() {
        _isMagicStarted = true;
        _isGeneratingLyrics = true;
        _isGeneratingMusic = false;
        _errorMessage = null;
        _generatedLyrics = null;
        _generatedAudioUrl = null;
        _hasGenerated = false;
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
      print('🎵 Selected Style: $_selectedStyle');
      print('✍️ Lyrical Theme: ${context.generateLyricalTheme()}');

      // Generate lyrics with OpenAI
      final locationVibe = '${context.location.ambiance} ${context.location.vibeWords.join(" ")}';
      final timeContext = '${context.calendar.timeOfDay} in ${context.calendar.season}';
      
      try {
        _generatedLyrics = await _openAIService.generateLyrics(
          musicStyle: _selectedStyle,
          weatherMood: context.weather.mood,
          timeContext: timeContext,
          locationVibe: locationVibe,
          temperature: context.weather.temperature.toString(),
          weatherDescription: context.weather.description,
        );

        print('✨ Generated Lyrics:\n$_generatedLyrics');
        
        // Ensure lyrics are within 400 character limit
        if (_generatedLyrics!.length > 400) {
          print('⚠️ Truncating lyrics to 400 characters');
          // Find the last complete word before 400 chars
          final truncated = _generatedLyrics!.substring(0, 400);
          final lastSpace = truncated.lastIndexOf(' ');
          _generatedLyrics = truncated.substring(0, lastSpace) + '...';
          print('📝 Truncated Lyrics:\n$_generatedLyrics');
        }
        
        setState(() {
          _isGeneratingLyrics = false;
          _isGeneratingMusic = true;
        });

        // Generate music with Uberduck
        print('\n🎵 Starting Uberduck music generation...');
        print('Style preset: $_selectedStyle');
        print('Voice model: Udzs_f45351fa-F13e-4466-8d7e-7cc5517edab9');
        print('Lyrics length: ${_generatedLyrics!.length} characters');
        
        final result = await UberduckService.generateSong(
          lyrics: _generatedLyrics!,
          style_preset: _selectedStyle,
          voicemodel_uuid: 'Udzs_f45351fa-F13e-4466-8d7e-7cc5517edab9',
        );

        print('\n📦 Uberduck Response:');
        print(result);

        if (result['status'] == 'OK' && result['output_url'] != null) {
          print('✅ Successfully generated music!');
          print('🎵 Audio URL: ${result['output_url']}');
          
          setState(() {
            _generatedAudioUrl = result['output_url'];
            _hasGenerated = true;
            _isGeneratingMusic = false;
          });
          
          // Load and play the audio
          await _audioPlayer.setUrl(_generatedAudioUrl!);
          _audioPlayer.play();
          
          // Start video playback when music starts
          widget.videoController.play();
        } else {
          print('❌ Uberduck response missing status OK or output_url');
          print('Response data: $result');
          throw Exception('Invalid response from Uberduck');
        }
      } catch (e) {
        print('❌ Error during music generation: $e');
        setState(() {
          _errorMessage = 'Failed to generate music: $e';
          _isGeneratingMusic = false;
          _isGeneratingLyrics = false;
        });
      }
      
    } catch (e) {
      print('❌ Error during context gathering: $e');
      setState(() {
        _errorMessage = 'Failed to gather context: $e';
        _isMagicStarted = false;
        _isGeneratingLyrics = false;
        _isGeneratingMusic = false;
      });
    }
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
    return Column(
      children: [
        // Style preset dropdown
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: caveShadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: amethyst.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: _stylePresets.entries.firstWhere(
              (entry) => entry.value == _selectedStyle,
              orElse: () => const MapEntry('Modern', 'Modern'),
            ).key,
            isExpanded: true,
            dropdownColor: deepCave,
            style: gemText.copyWith(color: silver),
            icon: Icon(Icons.arrow_drop_down, color: amethyst),
            underline: Container(), // Remove the default underline
            items: _stylePresets.keys.map((String displayName) {
              return DropdownMenuItem<String>(
                value: displayName,
                child: Text(
                  displayName,
                  style: gemText.copyWith(
                    color: _stylePresets[displayName] == _selectedStyle ? amethyst : silver,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedStyle = _stylePresets[newValue]!);
                HapticFeedback.mediumImpact();
              }
            },
          ),
        ),
        // Magic button
        GestureDetector(
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
        ),
      ],
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
        if (_isGeneratingLyrics) ...[
          Text(
            'Channeling Crystal Energy...',
            style: gemText.copyWith(
              color: amethyst,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crafting magical lyrics',
            style: gemText.copyWith(
              color: silver.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
        if (_isGeneratingMusic) ...[
          Text(
            'Weaving the Melody...',
            style: gemText.copyWith(
              color: emerald,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transforming lyrics into song',
            style: gemText.copyWith(
              color: silver.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(emerald),
              strokeWidth: 2,
            ),
          ),
        ],
        if (_hasGenerated && _generatedAudioUrl != null) ...[
          const SizedBox(height: 32),
          Text(
            '✨ Your Crystal Melody is Ready!',
            style: gemText.copyWith(
              color: emerald,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                  color: emerald,
                  size: 32,
                ),
                onPressed: () {
                  if (_audioPlayer.playing) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                  setState(() {});
                },
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(
                  Icons.replay,
                  color: sapphire,
                  size: 32,
                ),
                onPressed: () {
                  _audioPlayer.seek(Duration.zero);
                  _audioPlayer.play();
                },
              ),
            ],
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ruby.withOpacity(0.1),
              borderRadius: BorderRadius.circular(emeraldCut),
              border: Border.all(
                color: ruby.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: ruby,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crystal Magic Interrupted',
                  style: gemText.copyWith(
                    color: ruby,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: gemText.copyWith(
                    color: ruby.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _startMagic,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(emeraldCut),
                border: Border.all(
                  color: emerald.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Try Again ✨',
                style: gemText.copyWith(
                  color: emerald,
                  fontSize: 16,
                ),
              ),
            ),
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