import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/gem_theme.dart';
import 'pages/landing_page.dart';

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
      home: const LandingPage(),
    );
  }
} 