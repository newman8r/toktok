import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/cave_background.dart';
import '../widgets/gem_button.dart';
import 'creator_studio_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _crystalGrowthController;
  late final AnimationController _shimmerController;
  late final AnimationController _ambientController;
  
  // Cave parallax effect
  final _scrollController = ScrollController();
  double _parallaxOffset = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controllers
    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Start entrance animation
    _crystalGrowthController.forward();
    
    // Listen to scroll for parallax
    _scrollController.addListener(_updateParallax);
  }

  void _updateParallax() {
    setState(() {
      _parallaxOffset = _scrollController.offset * 0.5;
    });
  }

  @override
  void dispose() {
    _crystalGrowthController.dispose();
    _shimmerController.dispose();
    _ambientController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Parallax Cave Background
          Positioned.fill(
            child: _buildCaveBackground(),
          ),
          
          // Main Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Section
                _buildCaveEntrance(),
                
                // Features Section
                _buildGemVeins(),
                
                // Call to Action
                _buildCrystalChamber(),
              ],
            ),
          ),
          
          // Navigation Crystal Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCrystalNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaveBackground() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        return CustomPaint(
          painter: CaveBackgroundPainter(
            ambientProgress: _ambientController.value,
            parallaxOffset: _parallaxOffset,
          ),
        );
      },
    );
  }

  Widget _buildCaveEntrance() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Entrance Glow
          Center(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        amethyst.withOpacity(0.2 * _shimmerController.value),
                        deepCave.withOpacity(0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Welcome Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to TokTok',
                  style: crystalHeading.copyWith(
                    fontSize: 48,
                    shadows: [
                      Shadow(
                        color: amethyst.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Discover Digital Gems',
                  style: gemText.copyWith(
                    color: silver,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 48),
                _buildEnterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterButton() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _crystalGrowthController,
        curve: Curves.easeOutBack,
      ),
      child: GemButton(
        text: 'Enter the Mine',
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const CreatorStudioPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutQuart;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: caveTransition,
            ),
          );
        },
        gemColor: amethyst,
        isAnimated: true,
      ),
    );
  }

  Widget _buildGemVeins() {
    return Container(
      height: 600,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: // TODO: Add feature highlights with crystal formations
          const Placeholder(),
    );
  }

  Widget _buildCrystalChamber() {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: // TODO: Add call to action with special gem effects
          const Placeholder(),
    );
  }

  Widget _buildCrystalNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: caveShadow.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TokTok',
                  style: crystalHeading.copyWith(fontSize: 24),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavItem('About'),
                      _buildNavItem('Features'),
                      _buildNavItem('Contact'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        onEnter: (_) => _playGemSparkle(),
        child: Text(
          text,
          style: gemText.copyWith(color: silver),
        ),
      ),
    );
  }

  void _playGemSparkle() {
    HapticFeedback.lightImpact();
    // TODO: Add sparkle effect
  }
}

class CaveBackgroundPainter extends CustomPainter {
  final double ambientProgress;
  final double parallaxOffset;

  CaveBackgroundPainter({
    required this.ambientProgress,
    required this.parallaxOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement cave background with crystals and ambient glow
  }

  @override
  bool shouldRepaint(CaveBackgroundPainter oldDelegate) {
    return oldDelegate.ambientProgress != ambientProgress ||
           oldDelegate.parallaxOffset != parallaxOffset;
  }
} 