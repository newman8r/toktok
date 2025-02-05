import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/landing_page.dart';
import 'pages/creator_studio_page.dart';
import 'theme/gem_theme.dart';
import 'dart:math' as math;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _crystalController;

  @override
  void initState() {
    super.initState();
    _crystalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _crystalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show crystal loading animation while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: deepCave,
            body: Center(
              child: AnimatedBuilder(
                animation: _crystalController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer crystal glow
                      Transform.rotate(
                        angle: _crystalController.value * math.pi * 2,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                amethyst.withOpacity(0.2),
                                sapphire.withOpacity(0.2),
                                ruby.withOpacity(0.2),
                                amethyst.withOpacity(0.2),
                              ],
                              stops: const [0.0, 0.3, 0.6, 1.0],
                              transform: GradientRotation(_crystalController.value * math.pi * 2),
                            ),
                          ),
                        ),
                      ),
                      // Inner crystal
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              emerald.withOpacity(0.5),
                              emerald.withOpacity(0.8),
                            ],
                            transform: GradientRotation(_crystalController.value * math.pi),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: emerald.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(silver),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      // Crystal sparkles
                      ...List.generate(6, (index) {
                        final angle = (index / 6) * 2 * math.pi;
                        final radius = 40.0;
                        final offset = Offset(
                          math.cos(angle + _crystalController.value * math.pi * 2) * radius,
                          math.sin(angle + _crystalController.value * math.pi * 2) * radius,
                        );
                        return Transform.translate(
                          offset: offset,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: silver.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: emerald.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          );
        }
        
        // If authenticated, show creator studio
        if (snapshot.hasData) {
          return const CreatorStudioPage();
        }
        
        // If not authenticated, show landing page
        return const LandingPage();
      },
    );
  }
} 