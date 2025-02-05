import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/gem_theme.dart';
import 'pages/landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(
    fileName: ".env",
    mergeWith: {
      'CLOUDINARY_URL': 'cloudinary://649379854359992:gGLJsIerWHldXcOmlvG5tAk55FE@dmckmfjla',
      'CLOUDINARY_API_KEY': '649379854359992',
      'CLOUDINARY_API_SECRET': 'gGLJsIerWHldXcOmlvG5tAk55FE',
      'CLOUDINARY_CLOUD_NAME': 'dmckmfjla',
    }
  );
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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