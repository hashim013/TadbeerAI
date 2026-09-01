import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'package:tadbeerai/core/services/api_service.dart';
import 'package:tadbeerai/core/services/auth_service.dart';
import 'package:tadbeerai/core/models/user_profile_model.dart';
import 'package:tadbeerai/core/models/user_profile.dart';
import 'package:tadbeerai/core/services/user_profile_service.dart';
import 'package:tadbeerai/core/providers/language_provider.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';
import '../home/home_screen.dart';
import '../profile/category_selector_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _isSignUp = false;
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('0')) {
      p = '+92${p.substring(1)}';
    } else if (p.startsWith('92') && !p.startsWith('+')) {
      p = '+$p';
    } else if (!p.startsWith('+')) {
      p = '+92$p';
    }
    return p;
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      final success = await AuthService.instance.signInWithGoogle();
      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Check if profile exists on backend
          final existingProfile = await ApiService.getUserProfile(user.uid);
          final box = Hive.box<dynamic>('user_profile_box');
          
          if (existingProfile != null) {
            await box.put('user_profile', existingProfile.toJson());
            
            // Sync to UserProfileService / Firestore
            final userProfile = UserProfile(
              uid: user.uid,
              email: existingProfile.email,
              phone: existingProfile.phone,
              displayName: existingProfile.name,
              profileComplete: existingProfile.category.isNotEmpty && existingProfile.profileData.isNotEmpty,
            );
            await UserProfileService.instance.saveProfile(userProfile);

            if (existingProfile.category.isNotEmpty) {
              if (mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, true);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              }
              return;
            }
          } else {
            // Create new profile (independent of guest profile)
            String fcmToken = '';
            try {
              fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
            } catch (e) {
              debugPrint('FCM Token error: $e');
            }

            final profile = UserProfileModel(
              mode: 'account',
              category: '',
              name: user.displayName ?? user.email?.split('@').first ?? 'Google User',
              email: user.email ?? '',
              phone: user.phoneNumber ?? '',
              profileData: {},
              fcmToken: fcmToken,
            );

            await box.put('user_profile', profile.toJson());

            // Register on Backend
            await ApiService.registerUser(
              userId: user.uid,
              category: '',
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              fcmToken: fcmToken,
              profileData: {},
            );

            // Sync to UserProfileService / Firestore
            final userProfile = UserProfile(
              uid: user.uid,
              email: profile.email,
              phone: profile.phone,
              displayName: profile.name,
              profileComplete: false,
            );
            await UserProfileService.instance.saveProfile(userProfile);
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategorySelectorScreen()),
            );
          }
        }
      } else {
        _showError('Google Sign-In failed or cancelled.');
      }
    } catch (e) {
      _showError('Google Sign-In error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Sign Up Flow (independent of guest profile)
        final success = await AuthService.instance.signUpWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
        );

        if (success) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String fcmToken = '';
            try {
              fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
            } catch (e) {
              debugPrint('FCM Token error: $e');
            }

            final profile = UserProfileModel(
              mode: 'account',
              category: '',
              name: _emailCtrl.text.split('@').first,
              email: _emailCtrl.text.trim(),
              phone: _normalizePhone(_phoneCtrl.text.trim()),
              profileData: {},
              fcmToken: fcmToken,
            );

            // Save locally
            final box = Hive.box<dynamic>('user_profile_box');
            await box.put('user_profile', profile.toJson());

            // Register on Backend
            await ApiService.registerUser(
              userId: user.uid,
              category: '',
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              fcmToken: fcmToken,
              profileData: {},
            );

            // Sync to UserProfileService / Firestore
            final userProfile = UserProfile(
              uid: user.uid,
              email: profile.email,
              phone: profile.phone,
              displayName: profile.name,
              profileComplete: false,
            );
            await UserProfileService.instance.saveProfile(userProfile);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CategorySelectorScreen()),
              );
            }
          }
        } else {
          _showError('Registration failed. Email might be in use.');
        }
      } else {
        // Sign In Flow
        final success = await AuthService.instance.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
        );

        if (success) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final profile = await ApiService.getUserProfile(user.uid);
            if (profile != null) {
              final box = Hive.box<dynamic>('user_profile_box');
              await box.put('user_profile', profile.toJson());
              
              // Sync to UserProfileService / Firestore
              final userProfile = UserProfile(
                uid: user.uid,
                email: profile.email,
                phone: profile.phone,
                displayName: profile.name,
                profileComplete: profile.category.isNotEmpty && profile.profileData.isNotEmpty,
              );
              await UserProfileService.instance.saveProfile(userProfile);

              if (profile.category.isNotEmpty) {
                if (mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                }
                return;
              }
            }
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategorySelectorScreen()),
            );
          }
        } else {
          _showError('Sign-in failed. Please verify credentials.');
        }
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: TColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(delay: 100.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  'TadbeerAI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : TColors.textPrimary,
                  ),
                ),
                Text(
                  _isSignUp ? 'Create your advisor account'.tr(context) : 'Sign in to your account'.tr(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.tTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                TTextField(
                  controller: _emailCtrl,
                  label: 'Email'.tr(context),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Valid email required'.tr(context) : null,
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 12),
                  TTextField(
                    controller: _phoneCtrl,
                    label: 'Phone number (e.g. +923001234567)'.tr(context),
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number required'.tr(context);
                      final norm = _normalizePhone(v.trim());
                      if (!RegExp(r'^\+923\d{9}$').hasMatch(norm)) {
                        return 'Enter valid Pakistan phone number (+923xxxxxxxxx)'.tr(context);
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TTextField(
                  controller: _passwordCtrl,
                  label: 'Password'.tr(context),
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'.tr(context)
                      : null,
                ),
                const SizedBox(height: 24),
                TPrimaryButton(
                  label: _isSignUp ? 'Create account'.tr(context) : 'Sign in'.tr(context),
                  icon: _isSignUp ? Icons.person_add_rounded : Icons.login_rounded,
                  isLoading: _isLoading,
                  onTap: _handleEmailAuth,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18, color: TColors.primary),
                  label: Text('Sign in with Google'.tr(context)),
                  onPressed: _isLoading ? null : _handleGoogleAuth,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: TColors.primary, width: 1),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'.tr(context)
                        : 'New here? Create an account'.tr(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Account mode enables automated email, SMS, and push notification alerts from TadbeerAI.'.tr(context),
                  textAlign: TextAlign.center,
                  style: context.tCaption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
