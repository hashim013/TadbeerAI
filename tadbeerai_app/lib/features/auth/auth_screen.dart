import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tadbeerai/core/navigation/app_navigator.dart';
import 'package:tadbeerai/core/services/auth_service.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _isSignUp = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AuthService.instance.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await navigateAfterAuth(context);
      } else {
        _showError('Sign-in failed. Please try again.');
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = _isSignUp
        ? await AuthService.instance.signUpWithEmail(
            _emailCtrl.text, _passwordCtrl.text)
        : await AuthService.instance.signInWithEmail(
            _emailCtrl.text, _passwordCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await navigateAfterAuth(context);
      } else {
        _showError(_isSignUp
            ? 'Registration failed. Check email and password (min 6 chars).'
            : 'Invalid email or password.');
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    await AuthService.instance.signInAsGuest();
    if (mounted) await navigateAfterAuth(context);
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
      backgroundColor: isDark ? TColors.darkBg : TColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: ThemeToggleButton(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(delay: 100.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                Text(
                  'TadbeerAI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : TColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Content to Action Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? TColors.darkTextSecondary
                        : TColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 36),
                TTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TPrimaryButton(
                  label: _isSignUp ? 'Create account' : 'Sign in with email',
                  icon: Icons.login_rounded,
                  isLoading: _isLoading,
                  onTap: _handleEmailAuth,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.tBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: context.tCaption),
                    ),
                    Expanded(child: Divider(color: context.tBorder)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata_rounded, size: 28),
                      const SizedBox(width: 8),
                      const Text('Continue with Google',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _handleGuestSignIn,
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Registered users receive execution alerts via SMS, email, and push.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? TColors.darkTextSecondary
                        : TColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
