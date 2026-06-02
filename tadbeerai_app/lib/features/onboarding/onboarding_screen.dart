import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import '../../core/models/user_profile_model.dart';
import '../../core/providers/language_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';
import '../profile/category_selector_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final profile = UserProfileModel(
        mode: 'guest',
        category: '',
        name: 'Guest User',
        email: '',
        phone: '',
        profileData: {},
        fcmToken: '',
      );
      await box.put('user_profile', profile.toJson());
    } catch (e) {
      debugPrint('Error saving guest profile: $e');
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: TColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
              .animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 800.ms),
              const SizedBox(height: 32),
              Text(
                'TadbeerAI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: isDark ? Colors.white : TColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
              const SizedBox(height: 10),
              Text(
                'Pakistan\'s Premier AI Business Intelligence & Action Advisor'.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.tTextSecondary,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
              const Spacer(),
              TPrimaryButton(
                label: 'Create Account'.tr(context),
                icon: Icons.person_add_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('Continue as Guest'.tr(context)),
                onPressed: () => _continueAsGuest(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 24),
              Text(
                'TadbeerAI v1.0.0 · Built for AISeekho2026'.tr(context),
                textAlign: TextAlign.center,
                style: context.tCaption,
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
