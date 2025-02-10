import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' show Random, pi, cos, sin;
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/gem_service.dart';
import '../models/gem_model.dart';
import 'dart:ui' as ui;
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import 'video_crop_page.dart';
import 'gem_gallery_page.dart';
import 'gem_meta_edit_page.dart';

class ClipCombinerPage extends StatefulWidget {
  const ClipCombinerPage({super.key});

  @override
  State<ClipCombinerPage> createState() => _ClipCombinerPageState();
}

class _ClipCombinerPageState extends State<ClipCombinerPage> with TickerProviderStateMixin {
  final GemService _gemService = GemService();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _shimmerController;
  
  List<GemModel> _allGems = [];
  List<GemModel> _filteredGems = [];
  List<GemModel> _selectedGems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadGems();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGems() async {
    try {
      final gems = await _gemService.getAllGems();
      if (mounted) {
        setState(() {
          _allGems = gems;
          _filteredGems = gems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading gems: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterGems(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredGems = _allGems.where((gem) {
        final title = gem.title.toLowerCase();
        final description = gem.description.toLowerCase();
        return title.contains(_searchQuery) || description.contains(_searchQuery);
      }).toList();
    });
  }

  void _toggleGemSelection(GemModel gem) {
    setState(() {
      if (_selectedGems.contains(gem)) {
        _selectedGems.remove(gem);
      } else {
        _selectedGems.add(gem);
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _reorderSelectedGems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final gem = _selectedGems.removeAt(oldIndex);
      _selectedGems.insert(newIndex, gem);
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _createMovie() async {
    if (_selectedGems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get video URLs in order
      final videoUrls = _selectedGems.map((gem) => gem.cloudinaryUrl).toList();

      // Combine videos
      final combinedUrl = await _cloudinaryService.combineVideos(videoUrls);
      
      if (combinedUrl == null) {
        throw Exception('Failed to combine videos');
      }

      // Create new gem
      final gem = await _gemService.createGem(
        userId: user.uid,
        title: 'Combined Gem', // Default title
        description: 'Created from ${_selectedGems.length} gems', // Default description
        cloudinaryUrl: combinedUrl,
        cloudinaryPublicId: combinedUrl.split('/').last.split('.').first,
        bytes: 0, // We'll update this later
        sourceGemId: _selectedGems.first.id, // Reference the first gem as source
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Show metadata prompt
      final bool shouldEditMetadata = await showDialog<bool>(
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
                    'Your Combined Gem is Ready! ✨',
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
      ) ?? false;

      if (!mounted) return;

      if (shouldEditMetadata) {
        // Navigate to metadata edit page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GemMetaEditPage(
              gemId: gem.id,
              gem: gem,
            ),
          ),
        );
      } else {
        // Navigate to gem gallery
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const GemGalleryPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error creating combined video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating combined video: $e',
              style: gemText.copyWith(color: Colors.white),
            ),
            backgroundColor: ruby.withOpacity(0.8),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showCrystalParticles() {
    // Get the render box of the button
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final buttonSize = renderBox.size;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);

    // Create overlay entry for particles
    final overlay = Overlay.of(context);
    OverlayEntry? entry;  // Declare entry variable
    
    entry = OverlayEntry(  // Assign entry
      builder: (context) => Positioned(
        left: buttonPosition.dx,
        top: buttonPosition.dy,
        width: buttonSize.width,
        height: buttonSize.height,
        child: CrystalParticleEffect(
          onComplete: () {
            entry?.remove();  // Use safe call operator
          },
        ),
      ),
    );

    overlay.insert(entry);
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
                  painter: _CombinerBackgroundPainter(
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
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Combine Clips',
                  style: crystalHeading.copyWith(fontSize: 20),
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
              
              // Selected clips section
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _selectedGems.isEmpty ? 0 : 160,
                  child: _selectedGems.isEmpty
                      ? const SizedBox()
                      : _buildSelectedClipsSection(),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    style: gemText.copyWith(color: Colors.white),
                    onChanged: _filterGems,
                    decoration: InputDecoration(
                      hintText: 'Search your gems...',
                      hintStyle: gemText.copyWith(color: silver.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: silver.withOpacity(0.7)),
                      filled: true,
                      fillColor: caveShadow.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        borderSide: BorderSide(color: amethyst.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        borderSide: BorderSide(color: amethyst.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        borderSide: const BorderSide(color: amethyst),
                      ),
                    ),
                  ),
                ),
              ),

              // Grid of available clips
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: emerald),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childAspectRatio: 16 / 9,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGemTile(_filteredGems[index]),
                          childCount: _filteredGems.length,
                        ),
                      ),
                    ),
            ],
          ),

          // Create Movie Button
          if (_selectedGems.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _isProcessing
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: deepCave.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(emeraldCut),
                      border: Border.all(
                        color: amethyst.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(emerald),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Creating your combined gem...',
                          style: gemText.copyWith(color: silver),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient glow behind button
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(brilliantCut),
                          boxShadow: [
                            BoxShadow(
                              color: emerald.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: amethyst.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Crystal button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              emerald.withOpacity(0.9),
                              emerald.withOpacity(0.7),
                              sapphire.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(brilliantCut),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Crystal particle effect on tap
                              _showCrystalParticles();
                              _createMovie();
                            },
                            borderRadius: BorderRadius.circular(brilliantCut),
                            splashColor: emerald.withOpacity(0.3),
                            highlightColor: amethyst.withOpacity(0.1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Create Movie from ${_selectedGems.length} Clips',
                                    style: gemText.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: emerald.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedClipsSection() {
    return Container(
      height: 160,
      margin: const EdgeInsets.all(16.0),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Selected Clips',
              style: crystalHeading.copyWith(
                fontSize: 16,
                color: silver,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _selectedGems.length,
              onReorder: _reorderSelectedGems,
              itemBuilder: (context, index) {
                final gem = _selectedGems[index];
                return Container(
                  key: ValueKey(gem.id),
                  width: 160,
                  margin: const EdgeInsets.only(right: 12.0),
                  decoration: BoxDecoration(
                    color: deepCave.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(emeraldCut),
                    border: Border.all(
                      color: amethyst.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(emeraldCut),
                        child: Image.network(
                          gem.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _toggleGemSelection(gem),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: ruby,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(emeraldCut),
                            ),
                          ),
                          child: Text(
                            '${index + 1}. ${gem.title}',
                            style: gemText.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemTile(GemModel gem) {
    final isSelected = _selectedGems.contains(gem);
    
    return GestureDetector(
      onTap: () => _toggleGemSelection(gem),
      child: Container(
        decoration: BoxDecoration(
          color: deepCave.withOpacity(0.5),
          borderRadius: BorderRadius.circular(emeraldCut),
          border: Border.all(
            color: isSelected ? emerald : amethyst.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(emeraldCut),
              child: Image.network(
                gem.thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: emerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(emeraldCut),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gem.title,
                      style: gemText.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      gem.description,
                      style: gemText.copyWith(
                        color: silver,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombinerBackgroundPainter extends CustomPainter {
  final double progress;

  _CombinerBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          sapphire.withOpacity(0.1),
          amethyst.withOpacity(0.1),
          emerald.withOpacity(0.1),
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
  bool shouldRepaint(_CombinerBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CrystalParticleEffect extends StatefulWidget {
  final VoidCallback onComplete;

  const CrystalParticleEffect({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CrystalParticleEffect> createState() => _CrystalParticleEffectState();
}

class _CrystalParticleEffectState extends State<CrystalParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<CrystalParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initialize particles
    _particles = List.generate(20, (index) => CrystalParticle(random: _random));

    // Start animation
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CrystalParticlePainter(
            progress: _controller.value,
            particles: _particles,
          ),
        );
      },
    );
  }
}

class CrystalParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  CrystalParticle({required Random random})
      : angle = random.nextDouble() * 2 * pi,
        speed = random.nextDouble() * 100 + 50,
        size = random.nextDouble() * 8 + 2,
        color = [
          emerald,
          amethyst,
          sapphire,
        ][random.nextInt(3)];
}

class CrystalParticlePainter extends CustomPainter {
  final double progress;
  final List<CrystalParticle> particles;

  CrystalParticlePainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final distance = particle.speed * progress;
      final dx = cos(particle.angle) * distance;
      final dy = sin(particle.angle) * distance;
      final position = center + Offset(dx, dy);

      final paint = Paint()
        ..color = particle.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      // Draw crystal-shaped particle
      final path = Path();
      final particleSize = particle.size * (1 - progress * 0.5);
      path.moveTo(position.dx, position.dy - particleSize);
      path.lineTo(position.dx + particleSize, position.dy);
      path.lineTo(position.dx, position.dy + particleSize);
      path.lineTo(position.dx - particleSize, position.dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CrystalParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 