import 'package:flutter/material.dart';

// Gem Colors (Primary)
const Color amethyst = Color(0xFF9966CC);
const Color emerald = Color(0xFF50C878);
const Color ruby = Color(0xFFE0115F);
const Color sapphire = Color(0xFF0F52BA);

// Metallic Accents
const Color gold = Color(0xFFFFD700);
const Color silver = Color(0xFFC0C0C0);

// Cave Colors (Background)
const Color deepCave = Color(0xFF1A1A1A);
const Color caveShadow = Color(0xFF36454F);
const Color crystalGlow = Color(0x1FFFFFFF);

// Gem Cuts (Border Radius)
const double hexagonalCut = 0.0;
const double brilliantCut = 24.0;
const double emeraldCut = 12.0;

// Animation Durations
const Duration crystalGrow = Duration(milliseconds: 400);
const Duration gemSparkle = Duration(milliseconds: 200);
const Duration caveTransition = Duration(milliseconds: 600);

// Animation Curves
const Curve gemReveal = Curves.easeOutBack;
const Curve crystalForm = Curves.easeInOutQuart;

// Text Styles
const String displayFont = 'Audiowide';
const String bodyFont = 'SpaceMono';

const TextStyle crystalHeading = TextStyle(
  fontFamily: displayFont,
  fontSize: 32.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.5,
  color: Colors.white,
  shadows: [
    Shadow(
      color: crystalGlow,
      blurRadius: 10.0,
    ),
  ],
);

const TextStyle gemText = TextStyle(
  fontFamily: bodyFont,
  fontSize: 16.0,
  letterSpacing: 0.5,
  height: 1.5,
  color: silver,
);

// Button Styles
final ButtonStyle gemButton = ElevatedButton.styleFrom(
  backgroundColor: amethyst,
  foregroundColor: Colors.white,
  shape: BeveledRectangleBorder(
    borderRadius: BorderRadius.circular(emeraldCut),
  ),
  elevation: 8,
  shadowColor: crystalGlow,
  padding: const EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 16,
  ),
).copyWith(
  overlayColor: MaterialStateProperty.resolveWith<Color?>(
    (states) => states.contains(MaterialState.pressed)
        ? amethyst.withOpacity(0.7)
        : null,
  ),
);

// Gradients
const LinearGradient shimmerGradient = LinearGradient(
  colors: [
    Color(0x00FFFFFF),
    Color(0x33FFFFFF),
    Color(0x00FFFFFF),
  ],
  stops: [0.0, 0.5, 1.0],
);

// Box Decorations
final BoxDecoration crystalGlowEffect = BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: amethyst.withOpacity(0.2),
      blurRadius: 15,
      spreadRadius: 1,
    ),
  ],
);

ThemeData buildGemTheme() {
  return ThemeData(
    scaffoldBackgroundColor: deepCave,
    colorScheme: const ColorScheme.dark(
      primary: emerald,
      secondary: amethyst,
      surface: caveShadow,
      background: deepCave,
    ),
    textTheme: const TextTheme(
      displayLarge: crystalHeading,
      bodyLarge: gemText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: caveShadow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(emeraldCut),
        borderSide: const BorderSide(
          color: crystalGlow,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(emeraldCut),
        borderSide: BorderSide(
          color: amethyst.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(emeraldCut),
        borderSide: const BorderSide(
          color: amethyst,
          width: 2.0,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: gemButton,
    ),
  );
} 