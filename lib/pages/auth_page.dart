import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Crystal animation controllers
  late final AnimationController _shimmerController;
  late final AnimationController _crystalGrowthController;
  late final AnimationController _ambientController;
  
  @override
  void initState() {
    super.initState();
    
    // Shimmer effect for background
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // Crystal growth animation
    _crystalGrowthController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
    
    // Ambient glow animation
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Play crystal chime sound on page load
    HapticFeedback.mediumImpact();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _shimmerController.dispose();
    _crystalGrowthController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('📧 Starting account creation...');
      
      // Create the user
      final result = await _authService.registerWithEmailAndPassword(
        email,
        password,
      );
      
      if (result == null) {
        throw Exception('Failed to create your account. Please try again.');
      }
      
      print('🔥 Firebase Auth account created');
      
      // Create user profile in Firestore
      final user = UserModel(
        uid: result.user!.uid,
        email: result.user!.email!,
        displayName: _usernameController.text.trim(),
        createdAt: DateTime.now(),
      );
      
      await _userService.createUser(user);
      print('💾 User profile saved to Firestore');
      
      // Success feedback
      HapticFeedback.mediumImpact();
      print('✅ Account created and user profile saved successfully!');
      
      // Clear form
      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
        _usernameController.clear();
      }

      // Note: No need to navigate manually - AuthWrapper will handle it
      // Just wait a moment for Firebase Auth state to update
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        if (_errorMessage!.startsWith('Exception: ')) {
          _errorMessage = _errorMessage!.substring(11);
        }
      });
      HapticFeedback.heavyImpact();
      print('❌ Error during registration: $_errorMessage');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInAnonymously();
      if (result == null) {
        throw Exception('Failed to enter as a wanderer. Please try again.');
      }
      
      // Create anonymous user profile
      final user = UserModel(
        uid: result.user!.uid,
        displayName: 'Wanderer_${result.user!.uid.substring(0, 6)}',
        createdAt: DateTime.now(),
      );
      
      await _userService.createUser(user);
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to grant wanderer access. Please try again later.';
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
      body: Stack(
        children: [
          // Animated crystal cave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_shimmerController, _ambientController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _CrystalCavePainter(
                    shimmerProgress: _shimmerController.value,
                    ambientProgress: _ambientController.value,
                  ),
                );
              },
            ),
          ),
          
          // Crystal formations
          ..._buildCrystalFormations(),
          
          // Main content with glass effect
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(brilliantCut),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: caveShadow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(brilliantCut),
                        border: Border.all(
                          color: amethyst.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App title with crystal glow
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  emerald,
                                  amethyst,
                                  sapphire,
                                ],
                                transform: GradientRotation(_shimmerController.value * 2 * math.pi),
                              ).createShader(bounds),
                              child: const Text(
                                'TokTok',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontFamily: 'Audiowide',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create Your Mining Account',
                              style: gemText.copyWith(
                                color: silver,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            _buildCrystalInput(
                              controller: _usernameController,
                              label: 'Choose Your Miner Name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a miner name';
                                }
                                if (value.length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            _buildCrystalInput(
                              controller: _emailController,
                              label: 'Mining License (Email)',
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
                              label: 'Secret Code',
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your secret code';
                                }
                                if (value.length < 6) {
                                  return 'Code must be at least 6 characters';
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
                                  transform: GradientRotation(_shimmerController.value * math.pi),
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
                            
                            const SizedBox(height: 24),
                            
                            if (_isLoading)
                              Center(
                                child: _buildCrystalLoadingIndicator(),
                              )
                            else ...[
                              ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: _crystalGrowthController,
                                  curve: gemReveal,
                                ),
                                child: GemButton(
                                  onPressed: _handleSubmit,
                                  text: 'Create Account',
                                  gemColor: emerald,
                                  isAnimated: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: _crystalGrowthController,
                                  curve: Curves.easeOutBack,
                                ),
                                child: GemButton(
                                  onPressed: _continueAsGuest,
                                  text: 'Explore as Wanderer',
                                  gemColor: sapphire,
                                  style: GemButtonStyle.secondary,
                                  isAnimated: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCrystalFormations() {
    return List.generate(6, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * MediaQuery.of(context).size.width,
        top: random.nextDouble() * MediaQuery.of(context).size.height,
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _ambientController.value * math.pi * 2,
              child: Container(
                width: 100 + random.nextDouble() * 100,
                height: 100 + random.nextDouble() * 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      amethyst.withOpacity(0.1),
                      sapphire.withOpacity(0.1),
                    ],
                    transform: GradientRotation(_ambientController.value * math.pi),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
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
                amethyst.withOpacity(0.1),
                sapphire.withOpacity(0.1),
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
                  color: emerald.withOpacity(0.7),
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
            onTap: () => HapticFeedback.lightImpact(),
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
                emerald.withOpacity(0.2),
                emerald.withOpacity(0.4),
                emerald.withOpacity(0.2),
              ],
              transform: GradientRotation(_shimmerController.value * math.pi * 2),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(emerald),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

class _CrystalCavePainter extends CustomPainter {
  final double shimmerProgress;
  final double ambientProgress;

  _CrystalCavePainter({
    required this.shimmerProgress,
    required this.ambientProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          deepCave,
          caveShadow,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Crystal formations
    final crystalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
          ruby.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(shimmerProgress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    // Draw multiple crystal formations
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final startX = size.width * (i / 5);
      final startY = size.height * (math.sin(ambientProgress * math.pi + i) * 0.1 + 0.5);
      
      path.moveTo(startX, startY);
      path.lineTo(startX + 50, startY - 100);
      path.lineTo(startX + 100, startY);
      path.lineTo(startX + 50, startY + 100);
      path.close();
      
      canvas.drawPath(path, crystalPaint);
    }
  }

  @override
  bool shouldRepaint(_CrystalCavePainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
           oldDelegate.ambientProgress != ambientProgress;
  }
} 