import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/gem_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: deepCave,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const TokTokApp());
}

class TokTokApp extends StatelessWidget {
  const TokTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokTok',
      theme: buildGemTheme(),
      debugShowCheckedModeBanner: false,
      home: const SimpleLandingPage(),
    );
  }
}

class SimpleLandingPage extends StatelessWidget {
  const SimpleLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to TokTok',
              style: crystalHeading,
            ),
            const SizedBox(height: 24),
            Text(
              'Discover Digital Gems',
              style: gemText,
            ),
          ],
        ),
      ),
    );
  }
} 