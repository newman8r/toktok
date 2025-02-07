import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'creator_studio_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation controllers
  late final AnimationController _shimmerController;
  late final AnimationController _crystalGrowthController;
  late final AnimationController _particleController;
  late final AnimationController _strobeController;
  
  // Particle system
  final List<_Particle> _particles = [];
  final _random = math.Random();
  Offset? _lastTouchPoint;
  
  // Background radiation timer
  Timer? _backgroundRadiationTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Shimmer effect for crystals
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // Crystal growth animation
    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: crystalGrow,
    )..forward();
    
    // Fast strobe effect
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    // Particle system animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateParticles)
      ..repeat();
    
    // Background radiation - very occasional
    _backgroundRadiationTimer = Timer.periodic(
      const Duration(milliseconds: 2000), // Much slower emission
      (_) => _emitBackgroundParticle(),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _particleController.dispose();
    _strobeController.dispose();
    _backgroundRadiationTimer?.cancel();
    super.dispose();
  }

  void _emitBackgroundParticle() {
    if (!mounted) return;
    
    setState(() {
      if (_particles.length < 2) { // Keep just 1-2 background particles
        final screenSize = MediaQuery.of(context).size;
        final isHorizontal = _random.nextBool();
        final isStart = _random.nextBool();
        final position = isHorizontal
          ? Offset(
              isStart ? 0 : screenSize.width,
              _random.nextDouble() * screenSize.height,
            )
          : Offset(
              _random.nextDouble() * screenSize.width,
              isStart ? 0 : screenSize.height,
            );
            
        final angle = _random.nextDouble() * math.pi * 2;
        final speed = _random.nextDouble() * 2 + 1;
        _particles.add(_Particle(
          position: position,
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          color: sapphire,
        ));
      }
    });
  }

  void _emitTouchBurst(Offset position) {
    // Only emit if we have very few particles
    if (_particles.length < 5) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = _random.nextDouble() * 4 + 2;
      _particles.add(_Particle(
        position: position,
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        color: sapphire,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      // Update existing particles
      for (var particle in _particles) {
        particle.update();
      }
      
      // Aggressively remove particles
      _particles.removeWhere((particle) => particle.isDead);
      
      // Only add new particles if we have very few
      if (_lastTouchPoint != null && _particles.length < 3) {
        _emitTouchBurst(_lastTouchPoint!);
      }
    });
  }

  void _emitCenterBurst() {
    final screenSize = MediaQuery.of(context).size;
    final centerPosition = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );
    
    // Emit particles in a circular pattern
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final speed = _random.nextDouble() * 5 + 3;
      _particles.add(_Particle(
        position: centerPosition,
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        color: sapphire,
      ));
    }
  }

  void _emitButtonBurst(Offset buttonPosition) {
    // Create an upward fountain effect
    for (var i = 0; i < 12; i++) {
      final angle = (math.pi / 3) + (_random.nextDouble() * math.pi / 3); // Upward arc
      final speed = _random.nextDouble() * 8 + 4;
      _particles.add(_Particle(
        position: buttonPosition,
        velocity: Offset(
          math.cos(angle) * speed,
          -math.sin(angle) * speed, // Negative for upward motion
        ),
        color: sapphire,
      ));
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    // Get button position for particle burst
    final buttonContext = context.findRenderObject() as RenderBox?;
    if (buttonContext != null) {
      final buttonPosition = Offset(
        buttonContext.size.width / 2,
        buttonContext.size.height * 0.7,
      );
      _emitButtonBurst(buttonPosition);
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      print('🔑 Attempting login for email: $email');
      
      // Attempt to sign in
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (!mounted) return;
      
      if (userCredential != null) {
        print('✅ Login successful for user: ${userCredential.user?.uid}');
        
        // Success feedback with particles and haptics
        HapticFeedback.mediumImpact();
        
        // Clear form
        _emailController.clear();
        _passwordController.clear();
        
        // Navigate to creator studio
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              const CreatorStudioPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              // Fade transition combined with slide
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: caveTransition,
          ),
        );
      } else {
        throw Exception('Login failed - no user credential returned');
      }
    } catch (e) {
      print('❌ Login error: $e');
      setState(() {
        _errorMessage = e.toString();
        if (_errorMessage!.startsWith('Exception: ')) {
          _errorMessage = _errorMessage!.substring(11);
        }
      });
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: GestureDetector(
        onTapDown: (details) => setState(() => _lastTouchPoint = details.globalPosition),
        onTapUp: (_) => setState(() => _lastTouchPoint = null),
        onPanStart: (details) => setState(() => _lastTouchPoint = details.globalPosition),
        onPanUpdate: (details) => setState(() => _lastTouchPoint = details.globalPosition),
        onPanEnd: (_) => setState(() => _lastTouchPoint = null),
        child: Stack(
          children: [
            // Particle system with strobe effect
            AnimatedBuilder(
              animation: _strobeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CloudChamberPainter(
                    particles: _particles,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Crystal formations background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CrystalCavePainter(
                      shimmerProgress: _shimmerController.value,
                    ),
                  );
                },
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back to registration link
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.arrow_back, color: silver),
                          label: Text(
                            'Back to Registration',
                            style: gemText.copyWith(color: silver),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login form
                      ClipRRect(
                        borderRadius: BorderRadius.circular(brilliantCut),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: caveShadow.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(brilliantCut),
                              border: Border.all(
                                color: sapphire.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title with crystal glow
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        sapphire,
                                        amethyst,
                                      ],
                                      transform: GradientRotation(
                                        _shimmerController.value * 2 * math.pi
                                      ),
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontFamily: displayFont,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your mining credentials',
                                    style: gemText.copyWith(
                                      color: silver,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 48),
                                  
                                  _buildCrystalInput(
                                    controller: _emailController,
                                    label: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  _buildCrystalInput(
                                    controller: _passwordController,
                                    label: 'Password',
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          ruby.withOpacity(0.7),
                                          ruby.withOpacity(1.0),
                                        ],
                                        transform: GradientRotation(
                                          _shimmerController.value * math.pi
                                        ),
                                      ).createShader(bounds),
                                      child: Text(
                                        _errorMessage!,
                                        style: gemText.copyWith(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 32),
                                  
                                  if (_isLoading)
                                    _buildCrystalLoadingIndicator()
                                  else
                                    ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: _crystalGrowthController,
                                        curve: gemReveal,
                                      ),
                                      child: GemButton(
                                        onPressed: _handleLogin,
                                        text: 'Enter the Mine',
                                        gemColor: sapphire,
                                        isAnimated: true,
                                      ),
                                    ),
                                    
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Implement password reset
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Text(
                                      'Forgot Your Mining Code?',
                                      style: gemText.copyWith(
                                        color: silver.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverInteractiveElement(Offset position) {
    // Helper to check if a point is over any interactive elements
    // This is a simplified check - you might want to make it more precise
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    
    final localPosition = renderBox.globalToLocal(position);
    // Check if point is in the form area
    return localPosition.dy > renderBox.size.height * 0.2 &&
           localPosition.dy < renderBox.size.height * 0.8 &&
           localPosition.dx > renderBox.size.width * 0.2 &&
           localPosition.dx < renderBox.size.width * 0.8;
  }

  Widget _buildCrystalInput({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(emeraldCut),
            gradient: LinearGradient(
              colors: [
                sapphire.withOpacity(0.1),
                amethyst.withOpacity(0.1),
              ],
              transform: GradientRotation(_shimmerController.value * math.pi),
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: gemText.copyWith(color: silver),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: gemText.copyWith(color: silver.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(emeraldCut),
                borderSide: BorderSide(
                  color: silver.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(emeraldCut),
                borderSide: BorderSide(
                  color: sapphire.withOpacity(0.7),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(emeraldCut),
                borderSide: BorderSide(
                  color: ruby.withOpacity(0.7),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(emeraldCut),
                borderSide: BorderSide(
                  color: ruby.withOpacity(0.7),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: deepCave.withOpacity(0.7),
            ),
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onTap: () {
              HapticFeedback.lightImpact();
              _emitCenterBurst(); // Add particle burst on input focus
            },
          ),
        );
      },
    );
  }

  Widget _buildCrystalLoadingIndicator() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                sapphire.withOpacity(0.2),
                sapphire.withOpacity(0.4),
                sapphire.withOpacity(0.2),
              ],
              transform: GradientRotation(_shimmerController.value * math.pi * 2),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(sapphire),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  double angularVelocity;
  double radius;
  double angle;
  Color color;
  double life = 1.0;
  List<Offset> trail;
  static const double decay = 0.005; // Much slower decay (was 0.02)
  static const int maxTrailLength = 35; // Longer trails (was 15)
  
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
  }) : 
    angularVelocity = (math.Random().nextDouble() - 0.5) * 0.15, // Gentler rotation
    radius = math.Random().nextDouble() * 60 + 30, // Larger spirals
    angle = math.Random().nextDouble() * math.pi * 2,
    trail = [];

  void update() {
    trail.add(position);
    if (trail.length > maxTrailLength) {
      trail.removeAt(0);
    }

    angle += angularVelocity;
    final spiralOffset = Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    
    position += velocity + spiralOffset * 0.015; // Gentler spiral effect
    
    velocity = Offset(
      velocity.dx * 0.99, // Less velocity decay
      velocity.dy * 0.99,
    );

    life -= decay;
    radius *= 0.995; // Much slower radius decay
  }
  
  bool get isDead => life <= 0;
}

class _CloudChamberPainter extends CustomPainter {
  final List<_Particle> particles;
  
  _CloudChamberPainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.trail.length > 1) {
        final path = Path();
        path.moveTo(particle.trail.first.dx, particle.trail.first.dy);
        
        for (int i = 1; i < particle.trail.length; i++) {
          path.lineTo(particle.trail[i].dx, particle.trail[i].dy);
        }
        
        // Enhanced glow effect with three layers for better visibility
        for (var i = 2; i >= 0; i--) {
          final paint = Paint()
            ..color = particle.color.withOpacity(
              particle.life * (i == 0 ? 0.9 : 0.15) // More contrast
            )
            ..strokeWidth = i == 0 ? 1.0 : (2.0 + i) // Progressive widths
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
          
          if (i > 0) {
            paint.maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              i * 1.5, // Progressive blur
            );
          }
          
          canvas.drawPath(path, paint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(_CloudChamberPainter oldDelegate) => true;
}

class _CrystalCavePainter extends CustomPainter {
  final double shimmerProgress;
  
  _CrystalCavePainter({required this.shimmerProgress});
  
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
        transform: GradientRotation(shimmerProgress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    // Draw crystalline formations
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final startX = size.width * (i / 5);
      final startY = size.height * (math.sin(shimmerProgress * math.pi + i) * 0.1 + 0.5);
      
      path.moveTo(startX, startY);
      path.lineTo(startX + 50, startY - 100);
      path.lineTo(startX + 100, startY);
      path.lineTo(startX + 50, startY + 100);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(_CrystalCavePainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress;
  }
} 