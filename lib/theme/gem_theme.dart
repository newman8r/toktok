import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors from our style guide
const Color amethyst = Color(0xFF9966CC);
const Color emerald = Color(0xFF50C878);
const Color ruby = Color(0xFFE0115F);
const Color sapphire = Color(0xFF0F52BA);
const Color gold = Color(0xFFFFD700);
const Color silver = Color(0xFFC0C0C0);
const Color deepCave = Color(0xFF1A1A1A);
const Color caveShadow = Color(0xFF36454F);
const Color crystalGlow = Color(0x1FFFFFFF);

// Text Styles using Google Fonts
TextStyle get crystalHeading => GoogleFonts.audiowide(
  fontSize: 32.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.5,
  color: Colors.white,
  shadows: const [
    Shadow(
      color: crystalGlow,
      blurRadius: 10.0,
    ),
  ],
);

TextStyle get gemText => GoogleFonts.spaceMono(
  fontSize: 16.0,
  letterSpacing: 0.5,
  height: 1.5,
  color: Colors.white,
);

// Button Styles
final ButtonStyle gemButton = ElevatedButton.styleFrom(
  backgroundColor: amethyst,
  foregroundColor: Colors.white,
  shape: BeveledRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
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

// Animation Durations
const Duration crystalGrow = Duration(milliseconds: 400);
const Duration gemSparkle = Duration(milliseconds: 200);
const Duration caveTransition = Duration(milliseconds: 600);

// Animation Curves
const Curve gemReveal = Curves.easeOutBack;
const Curve crystalForm = Curves.easeInOutQuart;

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

// Theme Data
ThemeData buildGemTheme() {
  final baseTheme = ThemeData.dark();
  return baseTheme.copyWith(
    scaffoldBackgroundColor: deepCave,
    primaryColor: amethyst,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: amethyst,
      secondary: ruby,
      surface: caveShadow,
      background: deepCave,
    ),
    textTheme: GoogleFonts.spaceMonoTextTheme(baseTheme.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: gemButton,
    ),
  );
} 