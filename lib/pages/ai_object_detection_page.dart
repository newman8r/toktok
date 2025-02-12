import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/gem_theme.dart';
import '../services/video_analysis_service.dart';
import '../services/openai_service.dart';
import '../services/uberduck_service.dart';
import '../services/cloudinary_service.dart';
import '../services/gem_service.dart';
import '../services/auth_service.dart';
import 'gem_meta_edit_page.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/contextual_music_service.dart' hide UnifiedContext;
import '../models/unified_context.dart';

class AIObjectDetectionPage extends StatefulWidget {
  final String videoUrl;
  final VideoPlayerController videoController;

  const AIObjectDetectionPage({
    super.key,
    required this.videoUrl,
    required this.videoController,
  });

  @override
  State<AIObjectDetectionPage> createState() => _AIObjectDetectionPageState();
}

class _AIObjectDetectionPageState extends State<AIObjectDetectionPage> with SingleTickerProviderStateMixin {
  final VideoAnalysisService _analysisService = VideoAnalysisService();
  final OpenAIService _openAIService = OpenAIService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final GemService _gemService = GemService();
  final AuthService _authService = AuthService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ContextualMusicService _contextService = ContextualMusicService();
  late AnimationController _crystalController;
  List<String> _detectedObjects = [];
  bool _isAnalyzing = false;
  bool _isGeneratingMusic = false;
  bool _isSaving = false;
  bool _hasStartedAnalysis = false;
  String? _error;
  String? _generatedLyrics;
  String? _generatedAudioUrl;
  String? _finalVideoUrl;
  String _selectedStyle = "Modern"; // Default style
  String _currentStep = '';
  String? _gemId;
  
  // Available music styles from Uberduck
  final List<String> _musicStyles = [
    "Abstract", "Boom Bap", "Cloud Rap", "Conscious", "Drill", 
    "East Coast", "Grime", "Hardcore", "Lo-fi", "Melodic", 
    "Modern", "Old School", "Party", "Southern", "Underground", 
    "West Coast"
  ];

  // Crystal shard animation properties
  final List<Map<String, dynamic>> _crystalShards = List.generate(12, (index) {
    final random = math.Random();
    return {
      'angle': index * (math.pi * 2 / 12),
      'scale': 0.5 + random.nextDouble() * 0.5,
      'color': [emerald, amethyst, sapphire, ruby][random.nextInt(4)],
      'offset': Offset(
        random.nextDouble() * 40 - 20,
        random.nextDouble() * 40 - 20,
      ),
    };
  });

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
    _crystalController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _analyzeVideo() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _hasStartedAnalysis = true;
      _isGeneratingMusic = false;
      _error = null;
      _currentStep = 'Analyzing video frame...';
      _generatedLyrics = null;
      _generatedAudioUrl = null;
      _gemId = null;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Step 1: Analyze video frame and gather context in parallel
      print('🎬 Starting video analysis and context gathering...');
      final Future<List<String>> objectsFuture = _analysisService.analyzeVideoFrame(widget.videoUrl);
      final Future<UnifiedContext> contextFuture = _contextService.getUnifiedContext();
      
      final results = await Future.wait([objectsFuture, contextFuture]);
      final objects = results[0] as List<String>;
      final context = results[1] as UnifiedContext;
      
      if (!mounted) return;
      setState(() {
        _detectedObjects = objects;
        _currentStep = 'Generating lyrics...';
      });

      // Step 2: Generate lyrics based on detected objects and context
      print('🎵 Generating lyrics with rich context...');
      final locationVibe = '${context.location.ambiance} ${context.location.vibeWords.join(" ")}';
      final timeContext = '${context.calendar.timeOfDay} in ${context.calendar.season}';
      final weatherContext = '${context.weather.mood} weather (${context.weather.description})';
      final nearbyContext = context.location.nearbyPlaces.isNotEmpty 
          ? 'Near ${context.location.nearbyPlaces.take(2).join(" and ")}' 
          : '';
      final crowdContext = 'The scene is ${context.location.crowdLevel}';
      
      final prompt = '''
Create song lyrics (maximum 400 characters) that weave together these elements:
- Detected objects: ${objects.join(", ")}
- Location type: ${context.location.primaryCategory}
- Current vibe: $locationVibe
- Setting: $timeContext with $weatherContext
- Place: ${context.location.locationName} in ${context.location.neighborhood}
- Crowd & Scene: $crowdContext during ${context.location.timeContext}
${nearbyContext.isNotEmpty ? '- Nearby: $nearbyContext' : ''}

The lyrics should be in the style of $_selectedStyle music, but without directly mentioning the style.
Do not include any section labels (verse, chorus, etc.) - just write the lyrics as continuous text.
Make it professional and emotionally resonant. Only use normal a-z ascii characters, no special characters or emojis.
Create a cohesive narrative that connects the objects with the environment and atmosphere.
Focus on clever wordplay and strong delivery that fits the location's vibe.
''';

      final lyrics = await _openAIService.generateLyrics(
        prompt: prompt,
        maxLength: 400,
      );

      print('✨ Generated Lyrics:');
      print(lyrics);

      if (!mounted) return;
      setState(() {
        _generatedLyrics = lyrics;
        _currentStep = 'Generating music...';
        _isGeneratingMusic = true;
      });

      // Step 3: Generate music with Uberduck
      print('\n🎵 Starting Uberduck music generation...');
      final result = await UberduckService.generateSong(
        lyrics: lyrics,
        style_preset: _selectedStyle,
        voicemodel_uuid: 'Udzs_f45351fa-F13e-4466-8d7e-7cc5517edab9',
      );

      if (result['status'] == 'OK' && result['output_url'] != null) {
        print('✅ Successfully generated music!');
        print('🎵 Audio URL: ${result['output_url']}');
        
        if (!mounted) return;
        setState(() {
          _generatedAudioUrl = result['output_url'];
          _currentStep = 'Saving video...';
          _isGeneratingMusic = false;
          _isAnalyzing = false;
        });
        
        // Load and play the audio preview
        await _audioPlayer.setUrl(_generatedAudioUrl!);
        _audioPlayer.play();
        
        // Start video playback when music starts
        widget.videoController.play();

        // Save the video with the generated audio
        await _saveVideoWithAudio();
      } else {
        throw Exception('Invalid response from Uberduck');
      }
    } catch (e) {
      print('❌ Error in analysis flow: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to analyze video: $e';
          _isAnalyzing = false;
          _isGeneratingMusic = false;
          _currentStep = '';
        });
      }
    }
  }

  Future<void> _saveVideoWithAudio() async {
    if (_isSaving || _generatedAudioUrl == null) return;

    setState(() {
      _isSaving = true;
      _currentStep = 'Saving video with audio...';
    });

    try {
      // Step 1: Add audio to video using Cloudinary
      print('🎥 Combining video and audio in Cloudinary...');
      final videoWithAudio = await _cloudinaryService.addAudioToVideo(
        videoUrl: widget.videoUrl,
        audioUrl: _generatedAudioUrl!,
        audioDuration: await _audioPlayer.duration ?? const Duration(seconds: 30),
      );

      if (!mounted) return;
      setState(() {
        _finalVideoUrl = videoWithAudio;
        _currentStep = 'Creating gem...';
      });

      // Get current user
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create gem in Firestore
      final publicId = videoWithAudio.split('/').last.split('.').first;
      final gem = await _gemService.createGem(
        userId: user.uid,
        title: 'AI Generated Music Video',
        description: 'Created with Crystal Vision and UberDuck\nStyle: $_selectedStyle\nLyrics:\n$_generatedLyrics',
        cloudinaryUrl: videoWithAudio,
        cloudinaryPublicId: publicId,
        bytes: 0,
        tags: ['ai_music', 'crystal_vision', ..._detectedObjects],
        lyrics: _generatedLyrics,
        style_preset: _selectedStyle,
      );

      if (!mounted) return;
      setState(() {
        _gemId = gem.id;
        _currentStep = 'Gem created successfully! ✨';
      });

      // Show metadata edit modal
      final shouldEditMetadata = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: deepCave,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(emeraldCut),
              side: BorderSide(color: amethyst.withOpacity(0.5)),
            ),
            title: Text(
              '✨ Crystal Melody Created!',
              style: crystalHeading.copyWith(color: amethyst),
            ),
            content: Text(
              'Would you like to edit the title and description?',
              style: gemText.copyWith(color: silver),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Skip',
                  style: gemText.copyWith(color: silver),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(
                  'Edit',
                  style: gemText.copyWith(color: amethyst),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ?? false;

      if (shouldEditMetadata && mounted) {
        // Navigate to metadata edit page with correct parameters
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GemMetaEditPage(
              gemId: gem.id,
              gem: gem,
            ),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      print('❌ Error saving video: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to save video: $e';
          _isSaving = false;
          _currentStep = 'Complete!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Animated crystal background
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    // Crystal-themed app bar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: caveShadow.withOpacity(0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: amethyst.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: silver),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Crystal Vision Analysis',
                              style: crystalHeading.copyWith(fontSize: 24),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Video preview
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AspectRatio(
                        aspectRatio: widget.videoController.value.aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(emeraldCut),
                            border: Border.all(
                              color: sapphire.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sapphire.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VideoPlayer(widget.videoController),
                              AnimatedBuilder(
                                animation: _crystalController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _CrystalOverlayPainter(
                                      progress: _crystalController.value,
                                      objects: _detectedObjects,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Music style selection
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: caveShadow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(emeraldCut),
                        border: Border.all(
                          color: amethyst.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Music Style',
                            style: crystalHeading.copyWith(
                              fontSize: 20,
                              color: amethyst,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedStyle,
                            dropdownColor: deepCave,
                            style: gemText.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: deepCave.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(emeraldCut),
                                borderSide: BorderSide(
                                  color: amethyst.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(emeraldCut),
                                borderSide: BorderSide(
                                  color: amethyst.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(emeraldCut),
                                borderSide: const BorderSide(
                                  color: amethyst,
                                ),
                              ),
                            ),
                            items: _musicStyles.map((String style) {
                              return DropdownMenuItem<String>(
                                value: style,
                                child: Text(style),
                              );
                            }).toList(),
                            onChanged: _isAnalyzing ? null : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStyle = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Detected objects and lyrics
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      decoration: BoxDecoration(
                        color: caveShadow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(emeraldCut),
                        border: Border.all(
                          color: amethyst.withOpacity(0.3),
                        ),
                      ),
                      child: _isAnalyzing
                          ? _buildAnalyzingState()
                          : _detectedObjects.isEmpty
                              ? _buildEmptyState()
                              : _buildResultsList(),
                    ),

                    // Analyze button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _hasStartedAnalysis 
                            ? _buildProgressIndicator()
                            : ElevatedButton(
                                onPressed: _isAnalyzing ? null : _analyzeVideo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: sapphire.withOpacity(0.3),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(emeraldCut),
                                    side: BorderSide(
                                      color: sapphire.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Analyze Video Frame 👁️✨',
                                  style: crystalHeading.copyWith(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crystal shards animation
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: _crystalShards.map((shard) {
                return AnimatedBuilder(
                  animation: _crystalController,
                  builder: (context, child) {
                    final angle = shard['angle'] + _crystalController.value * math.pi * 2;
                    final scale = shard['scale'] * (0.8 + math.sin(_crystalController.value * math.pi * 2) * 0.2);
                    
                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(
                          (60 + shard['offset'].dx).toDouble(),
                          (60 + shard['offset'].dy).toDouble(),
                        )
                        ..rotateZ(angle)
                        ..scale(scale),
                      child: Icon(
                        Icons.diamond_outlined,
                        color: shard['color'].withOpacity(0.6),
                        size: 24,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentStep,
            style: crystalHeading.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering hidden treasures...',
            style: gemText.copyWith(
              color: silver,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_red_eye_outlined,
            color: silver.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Crystal Vision Awaits',
            style: crystalHeading.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap analyze to reveal hidden objects',
            style: gemText.copyWith(
              color: silver,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Detected Objects Section
        Text(
          'Detected Objects',
          style: crystalHeading.copyWith(
            fontSize: 20,
            color: sapphire,
          ),
        ),
        const SizedBox(height: 12),
        ..._detectedObjects.map((object) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sapphire.withOpacity(0.1),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: sapphire.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sapphire.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  object,
                  style: gemText.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),

        // Generated Lyrics Section
        if (_generatedLyrics != null) ...[
          const SizedBox(height: 24),
          Text(
            'Generated Lyrics',
            style: crystalHeading.copyWith(
              fontSize: 20,
              color: amethyst,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: amethyst.withOpacity(0.1),
              borderRadius: BorderRadius.circular(emeraldCut),
              border: Border.all(
                color: amethyst.withOpacity(0.3),
              ),
            ),
            child: Text(
              _generatedLyrics!,
              style: gemText.copyWith(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],

        // Audio Controls Section
        if (_generatedAudioUrl != null) ...[
          const SizedBox(height: 24),
          Text(
            'Generated Music',
            style: crystalHeading.copyWith(
              fontSize: 20,
              color: emerald,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(emeraldCut),
              border: Border.all(
                color: emerald.withOpacity(0.3),
              ),
            ),
            child: Row(
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
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: sapphire.withOpacity(0.1),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: sapphire.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_gemId != null) ...[
            Icon(
              Icons.check_circle_outline,
              color: emerald,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Gem Created Successfully! ✨',
              style: crystalHeading.copyWith(
                fontSize: 16,
                color: emerald,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentStep,
              style: gemText.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
          sapphire.withOpacity(0.1),
          amethyst.withOpacity(0.1),
          ruby.withOpacity(0.1),
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

class _CrystalOverlayPainter extends CustomPainter {
  final double progress;
  final List<String> objects;

  _CrystalOverlayPainter({
    required this.progress,
    required this.objects,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (objects.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [
          sapphire.withOpacity(0.6),
          amethyst.withOpacity(0.6),
          ruby.withOpacity(0.6),
          sapphire.withOpacity(0.6),
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    // Draw scanning effect
    final scanY = size.height * progress;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      paint,
    );

    // Draw crystal corners
    final cornerSize = size.width * 0.1;
    final cornerPath = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(0, 0)
      ..lineTo(cornerSize, 0);
    
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(
        i < 2 ? 0 : size.width,
        i.isEven ? 0 : size.height,
      );
      canvas.rotate(i * math.pi / 2);
      canvas.drawPath(cornerPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CrystalOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.objects != objects;
  }
} 