import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTANT: Verify these import paths match your folder structure ---
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // This function acts like the "Brain" of the app startup
  Future<void> _checkSession() async {
    // 1. Show the splash UI for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // 2. Access the device's local memory
    final prefs = await SharedPreferences.getInstance();

    // 3. Look for the key 'email' which we saved during the Login process
    final String? userEmail = prefs.getString('email');

    // Safety check to ensure the app is still active
    if (!mounted) return;

    // 4. Decide where to navigate
    if (userEmail != null && userEmail.isNotEmpty) {
      // User is already logged in (Stay logged in mechanism)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // No user found in memory, take them to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // UniBook Logo Icon
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              "UniBook",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Text(
              "Your Campus, Your Community",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            // Loading Indicator to show the app is working
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            const SizedBox(height: 50),
            // Version Info
            Text(
              "V 1.0.0",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}