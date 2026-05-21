import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// Routes user to Home or Onboarding based on profile completeness.
Future<void> navigateAfterAuth(BuildContext context) async {
  if (AuthService.instance.isGuest) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return;
  }

  UserProfile? profile;
  try {
    profile = await UserProfileService.instance.getOrCreateFromAuth();
  } catch (_) {
    profile = null;
  }

  if (!context.mounted) return;

  if (profile == null || !profile.profileComplete) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
