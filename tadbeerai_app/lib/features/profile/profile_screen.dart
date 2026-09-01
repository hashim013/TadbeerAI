import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _notifySms = true;
  bool _notifyEmail = true;
  bool _notifyPush = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final profile =
        await UserProfileService.instance.loadProfile(user.uid) ??
            await UserProfileService.instance.getOrCreateFromAuth();
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _nameCtrl.text = profile.displayName;
    setState(() {
      _profile = profile;
      _notifySms = profile.notifySms;
      _notifyEmail = profile.notifyEmail;
      _notifyPush = profile.notifyPush;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_profile == null) return;
    setState(() => _saving = true);
    final updated = _profile!.copyWith(
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      notifySms: _notifySms,
      notifyEmail: _notifyEmail,
      notifyPush: _notifyPush,
      profileComplete: true,
    );
    await UserProfileService.instance.saveProfile(updated);
    if (mounted) {
      setState(() {
        _profile = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: TColors.teal,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = AuthService.instance.isGuest;

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Profile',
        subtitle: isGuest ? 'Guest mode' : user?.email ?? '',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TColors.primary))
          : isGuest
              ? _buildGuestBody()
              : _buildProfileBody(),
    );
  }

  Widget _buildGuestBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TEmptyState(
            icon: Icons.person_outline_rounded,
            title: 'Guest account',
            subtitle:
                'Sign in to register your phone and email for execution alerts.',
          ),
          const SizedBox(height: 24),
          TPrimaryButton(
            label: 'Sign in',
            icon: Icons.login_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ).then((value) {
                if (value == true && mounted) {
                  _load();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_profile != null && !_profile!.profileComplete)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColors.amberLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: TColors.amberDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complete your profile to receive execution alerts.',
                    style: context.tBodyMd.copyWith(color: TColors.amberDark),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  ),
                  child: const Text('Complete'),
                ),
              ],
            ),
          ),
        TTextField(controller: _nameCtrl, label: 'Name', icon: Icons.person_outline),
        const SizedBox(height: 12),
        TTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TTextField(
          controller: _phoneCtrl,
          label: 'Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const TSectionLabel(label: 'Notifications'),
        SwitchListTile(
          title: const Text('SMS'),
          value: _notifySms,
          onChanged: (v) => setState(() => _notifySms = v),
        ),
        SwitchListTile(
          title: const Text('Email'),
          value: _notifyEmail,
          onChanged: (v) => setState(() => _notifyEmail = v),
        ),
        SwitchListTile(
          title: const Text('Push'),
          value: _notifyPush,
          onChanged: (v) => setState(() => _notifyPush = v),
        ),
        const SizedBox(height: 24),
        TPrimaryButton(
          label: 'Save changes',
          isLoading: _saving,
          onTap: _save,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _signOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
