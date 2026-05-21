import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _notifySms = true;
  bool _notifyEmail = true;
  bool _notifyPush = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailCtrl.text = user?.email ?? '';
    _nameCtrl.text = user?.displayName ?? '';
    _phoneCtrl.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_notifySms && !_notifyEmail && !_notifyPush) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable at least one notification channel'),
          backgroundColor: TColors.amber,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = UserProfile(
      uid: user.uid,
      email: _emailCtrl.text.trim(),
      phone: _normalizePhone(_phoneCtrl.text.trim()),
      displayName: _nameCtrl.text.trim(),
      notifySms: _notifySms,
      notifyEmail: _notifyEmail,
      notifyPush: _notifyPush,
      profileComplete: true,
    );

    await UserProfileService.instance.saveProfile(profile);
    await NotificationService.instance.initialize();

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  String _normalizePhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!p.startsWith('+') && p.startsWith('0')) {
      p = '+92${p.substring(1)}';
    } else if (!p.startsWith('+')) {
      p = '+$p';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Complete registration',
        subtitle: 'Phone & email for execution alerts',
        showBack: false,
        actions: [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Stay informed when TadbeerAI executes actions on your behalf.',
                style: context.tBodyMd,
              ).animate().fadeIn(),
              const SizedBox(height: 24),
              TTextField(
                controller: _nameCtrl,
                label: 'Display name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              TTextField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TTextField(
                controller: _phoneCtrl,
                label: 'Phone (E.164, e.g. +923001234567)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const TSectionLabel(label: 'Notification channels'),
              const SizedBox(height: 8),
              _ChannelTile(
                title: 'SMS alerts',
                subtitle: 'Execution summaries via text',
                icon: Icons.sms_outlined,
                value: _notifySms,
                onChanged: (v) => setState(() => _notifySms = v),
              ),
              _ChannelTile(
                title: 'Email alerts',
                subtitle: 'Detailed reports in your inbox',
                icon: Icons.mail_outline_rounded,
                value: _notifyEmail,
                onChanged: (v) => setState(() => _notifyEmail = v),
              ),
              _ChannelTile(
                title: 'Push notifications',
                subtitle: 'Instant alerts on this device',
                icon: Icons.notifications_active_outlined,
                value: _notifyPush,
                onChanged: (v) => setState(() => _notifyPush = v),
              ),
              const SizedBox(height: 32),
              TPrimaryButton(
                label: 'Save & continue',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: context.tCard,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: TColors.primary,
        secondary: Icon(icon, color: TColors.primary),
        title: Text(title,
            style: context.tBodyMd.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: context.tCaption),
      ),
    );
  }
}
