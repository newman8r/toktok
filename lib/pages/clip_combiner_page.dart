import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/gem_service.dart';
import '../models/gem_model.dart';
import 'dart:ui' as ui;

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
              child: GemButton(
                text: 'Create Movie from ${_selectedGems.length} Clips',
                onPressed: () {
                  // TODO: Implement movie creation
                  print('Creating movie from clips: ${_selectedGems.map((g) => g.title).join(", ")}');
                },
                gemColor: emerald,
                isAnimated: true,
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