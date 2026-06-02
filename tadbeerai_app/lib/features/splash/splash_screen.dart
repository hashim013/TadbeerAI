// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user_profile_model.dart';
import '../onboarding/onboarding_screen.dart';
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
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        final box = Hive.box<dynamic>('user_profile_box');
        final dynamic raw = box.get('user_profile');
        bool profileComplete = false;

        if (raw != null) {
          final profile = UserProfileModel.fromJson(Map<String, dynamic>.from(raw));
          if (profile.category.isNotEmpty && profile.profileData.isNotEmpty) {
            profileComplete = true;
          }
        } else {
          // If local profile is missing but Firebase User is logged in, try fetching from backend
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final profile = await ApiService.getUserProfile(user.uid);
              if (profile != null) {
                await box.put('user_profile', profile.toJson());
                if (profile.category.isNotEmpty && profile.profileData.isNotEmpty) {
                  profileComplete = true;
                }
              }
            } catch (e) {
              debugPrint('Failed to auto-restore profile: $e');
            }
          }
        }

        if (mounted) {
          if (profileComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const OnboardingScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            )
            .animate()
            .fadeIn(duration: 1000.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 1000.ms, curve: Curves.easeOut),
            SizedBox(height: 16),
            Text(
              'Content to Action Intelligence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.tTextSecondary,
                letterSpacing: 0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),
            SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: TColors.primary,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
