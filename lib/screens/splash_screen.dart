import 'dart:async';
import 'package:doc/profileprofile/profile.dart';
import 'package:flutter/material.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/profileprofile/professional_profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// ⏳ Initialize splash logic and route
  Future<void> _initApp() async {
    // Give a short delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    // Then check login status
    final isLoggedIn = await SessionManager.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final userId = await SessionManager.getUserId();
      debugPrint('✅ User already logged in. Redirecting to Profile page.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalProfileViewPage(profileId: userId ?? ''),
        ),
      );
    } else {
      debugPrint('🚪 No active session found. Redirecting to Login.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌟 App logo
            Image.asset('assets/logo2.png', height: 120, width: 120),
            const SizedBox(height: 25),
            const Text(
              'Surgeon Search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
