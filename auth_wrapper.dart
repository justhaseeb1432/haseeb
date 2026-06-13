import 'package:ai_chat_pro/auth.dart';
import 'package:ai_chat_pro/chat.dart';
import 'package:ai_chat_pro/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return ChatScreen(
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
            },
            userName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
            userEmail: user.email ?? 'No Email',
          );
        }

        return AuthScreen(
          onLoginSuccess: (name, email) {
            // No longer strictly needed for state management, 
            // but kept for UI callbacks if necessary.
          },
        );
      },
    );
  }
}
