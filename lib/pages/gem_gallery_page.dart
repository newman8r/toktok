/*
 * GemGalleryPage: Main collection view for user's video content
 * 
 * This page implements a responsive grid layout of user's video gems with:
 * - Real-time search and filtering by title, description, and tags
 * - Crystal-themed UI with smooth animations and transitions
 * - Pull-to-refresh and lazy loading for performance
 * - Interactive tag system with suggestions
 * - Usage statistics and collection insights
 * 
 * The UI is designed to feel like browsing a collection of precious gems,
 * with each video card having glass-morphic effects and smooth animations.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../theme/gem_theme.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../widgets/gem_button.dart';
import 'gem_explorer_page.dart';
import '../services/gem_service.dart';
import '../services/auth_service.dart';
import '../models/gem_model.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import '../pages/creator_studio_page.dart';

class GemGalleryPage extends StatefulWidget {
  const GemGalleryPage({super.key});

  @override
  State<GemGalleryPage> createState() => _GemGalleryPageState();
}

class _GemGalleryPageState extends State<GemGalleryPage> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _crystalGrowthController;
  final GemService _gemService = GemService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<GemModel> _userGems = [];
  List<GemModel> _filteredGems = [];
  List<String> _suggestedTags = [];
  int _hiddenGemsCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: crystalGrow,
    )..forward();

    _searchController.addListener(_handleSearch);
    _loadUserGems();
  }

  // Handles real-time search functionality across title, description, and tags
  // Updates filtered gems list and tag suggestions as user types
  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGems = _userGems;
        _hiddenGemsCount = 0;
        _suggestedTags = _getAllUniqueTags();
      } else {
        _filteredGems = _userGems.where((gem) {
          return gem.title.toLowerCase().contains(query) ||
                 gem.description.toLowerCase().contains(query) ||
                 gem.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
        _hiddenGemsCount = _userGems.length - _filteredGems.length;
        _suggestedTags = _getAllUniqueTags()
            .where((tag) => tag.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // Retrieves all unique tags from user's gems
  // Used for tag suggestions and filtering
  List<String> _getAllUniqueTags() {
    return _userGems
        .expand((gem) => gem.tags)
        .toSet()
        .toList();
  }

  void _onTagSelected(String tag) {
    _searchController.text = tag;
    _handleSearch();
  }

  // Loads user's gems from Firestore
  // Handles loading states and error conditions
  Future<void> _loadUserGems() async {
    try {
      print('🔄 Starting to load user gems...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _authService.currentUser;
      print('👤 Current user: ${user?.uid}');
      
      if (user == null) throw Exception('User not authenticated');

      final gems = await _gemService.getUserGems(user.uid);
      print('💎 Loaded ${gems.length} gems from service');
      
      if (mounted) {
        setState(() {
          _userGems = gems;
          _filteredGems = gems;
          _isLoading = false;
        });
        print('✨ Updated UI with ${_userGems.length} gems');
      }
    } catch (e) {
      print('❌ Error in _loadUserGems: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load gems: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Try to pop normally
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // If we can't pop, go to CreatorStudio instead of black screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatorStudioPage(),
            ),
          );
        }
        return false; // We handle the navigation ourselves
      },
      child: Scaffold(
        backgroundColor: deepCave,
        body: Stack(
          children: [
            // Animated crystal cave background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CrystalBackgroundPainter(
                      progress: _shimmerController.value,
                    ),
                  );
                },
              ),
            ),
            
            // Main content
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await _loadUserGems();
                },
                color: amethyst,
                backgroundColor: deepCave,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Crystal App Bar
                    _buildCrystalAppBar(),
                    
                    // Pull to refresh
                    CupertinoSliverRefreshControl(
                      onRefresh: _loadUserGems,
                      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.only(top: 16),
                            child: const CircularProgressIndicator(
                              color: amethyst,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Stats Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 16),
                            _buildTagSuggestions(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                          ],
                        ),
                      ),
                    ),

                    // Gallery Grid or Loading/Error State
                    if (_isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: amethyst,
                          ),
                        ),
                      )
                    else if (_error != null)
                      SliverFillRemaining(
                        child: Center(
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
                                _error!,
                                style: gemText.copyWith(color: ruby),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              GemButton(
                                text: 'Try Again',
                                onPressed: _loadUserGems,
                                gemColor: emerald,
                                isAnimated: true,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_userGems.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.diamond_outlined,
                                  color: silver,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No gems found in your collection yet.',
                                  style: gemText.copyWith(
                                    color: silver,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 1.0,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final gem = _filteredGems[index];
                              return _buildGemCard(gem);
                            },
                            childCount: _filteredGems.length,
                          ),
                        ),
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

  // Builds the crystal-themed app bar with blur effects
  // Includes navigation and title with custom styling
  Widget _buildCrystalAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            title: Text(
              'Gem Collection',
              style: crystalHeading.copyWith(fontSize: 24),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    amethyst.withOpacity(0.3),
                    deepCave.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: silver),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatorStudioPage(),
              ),
            );
          }
        },
      ),
    );
  }

  // Creates the statistics section showing gem counts and storage usage
  // Adapts layout based on screen width
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 400;
          return Column(
            children: [
              Text(
                'Your Gem Collection',
                style: crystalHeading.copyWith(
                  fontSize: isNarrow ? 24 : 28,
                  color: amethyst,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isNarrow ? 16 : 24),
              Wrap(
                spacing: isNarrow ? 8 : 16,
                runSpacing: isNarrow ? 16 : 24,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Gems', 
                    '${_userGems.length}', 
                    emerald,
                    isNarrow: isNarrow,
                  ),
                  _buildStatItem(
                    'Storage Used', 
                    _formatFileSize(_calculateTotalSize()), 
                    sapphire,
                    isNarrow: isNarrow,
                  ),
                  _buildStatItem(
                    'Latest', 
                    _userGems.isEmpty ? '-' : _formatTimeAgo(
                      _userGems.first.createdAt
                    ), 
                    ruby,
                    isNarrow: isNarrow,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Formats file size from bytes to human-readable format (B, KB, MB, GB)
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _calculateTotalSize() {
    return _userGems.fold(0, (total, gem) => total + gem.bytes);
  }

  Widget _buildStatItem(String label, String value, Color color, {bool isNarrow = false}) {
    return Container(
      width: isNarrow ? 100 : 120,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isNarrow ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              value,
              style: crystalHeading.copyWith(
                fontSize: isNarrow ? 20 : 24,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: gemText.copyWith(
              color: silver,
              fontSize: isNarrow ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Builds individual gem cards with thumbnails and metadata
  // Includes hover effects and navigation to gem explorer
  Widget _buildGemCard(GemModel gem) {
    final thumbnailUrl = _cloudinaryService.getThumbnailUrl(gem.cloudinaryUrl);
    final isCloudinaryUrl = thumbnailUrl.contains('cloudinary.com');
    
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _crystalGrowthController,
        curve: gemReveal,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                GemExplorerPage(
                  recordedVideo: File(''), // Required but not used for existing gems
                  cloudinaryUrl: gem.cloudinaryUrl,
                  gemId: gem.id,  // Pass the gem ID to track which gem we're editing
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
        },
        child: Container(
          decoration: BoxDecoration(
            color: caveShadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: amethyst.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Video thumbnail
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(emeraldCut),
                  child: isCloudinaryUrl
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : FutureBuilder<String?>(
                        future: _cloudinaryService.generateLocalThumbnail(thumbnailUrl),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            );
                          }
                          return _buildPlaceholder();
                        },
                      ),
                ),
              ),

              // Play icon overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: deepCave.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Info overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(emeraldCut),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            caveShadow.withOpacity(0.5),
                            deepCave.withOpacity(0.8),
                          ],
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
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: silver,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeAgo(gem.createdAt),
                                style: gemText.copyWith(
                                  color: silver,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sapphire.withOpacity(0.2),
            amethyst.withOpacity(0.2),
          ],
        ),
      ),
      child: const Icon(
        Icons.play_circle_outline,
        color: silver,
        size: 48,
      ),
    );
  }

  // Formats relative time (e.g., "2h ago", "3d ago")
  // Used for displaying gem creation times
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Creates the search bar with real-time filtering
  // Includes clear button and styling
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: silver),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: gemText.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search gems by title, description, or tags...',
                hintStyle: gemText.copyWith(
                  color: silver.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: silver),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }

  // Displays tag suggestions and filtered gem count
  // Allows quick filtering by clicking tags
  Widget _buildTagSuggestions() {
    if (_suggestedTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hiddenGemsCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$_hiddenGemsCount gems filtered out',
              style: gemText.copyWith(
                color: silver.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTags.map((tag) {
            return GestureDetector(
              onTap: () => _onTagSelected(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sapphire.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sapphire.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: gemText.copyWith(
                    color: silver,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
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