import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/gem_theme.dart';
import 'widgets/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/creator_studio_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firebase Auth settings
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
    
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    // Add more detailed error information
    if (e is FirebaseException) {
      print('Firebase Error Code: ${e.code}');
      print('Firebase Error Message: ${e.message}');
    }
  }
  
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

class SafeNavigationObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // If we're about to pop to nothing (black screen), redirect to CreatorStudio
    if (previousRoute == null && navigator != null) {
      navigator!.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CreatorStudioPage(),
        ),
      );
    }
  }
}

class TokTokApp extends StatelessWidget {
  const TokTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokTok',
      theme: buildGemTheme(),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      navigatorObservers: [SafeNavigationObserver()],
    );
  }
} 