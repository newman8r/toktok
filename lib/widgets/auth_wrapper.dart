import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../pages/creator_studio_page.dart';
import '../pages/auth_page.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          print('🎯 User authenticated, navigating to CreatorStudioPage');
          // User is signed in
          return const CreatorStudioPage();
        }

        print('🔒 No user found, showing AuthPage');
        // User is not signed in
        return const AuthPage();
      },
    );
  }
} 