import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tadbeerai/core/models/user_profile_model.dart';
import 'package:tadbeerai/core/services/api_service.dart';
import 'package:tadbeerai/core/services/auth_service.dart';
import 'package:tadbeerai/core/providers/theme_provider.dart';
import 'package:tadbeerai/core/providers/language_provider.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _profileBox;
  late Box _settingsBox;
  UserProfileModel? _profile;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _isEditingProfile = false;
  bool _isLoading = false;

  // Notifications preferences (Account only)
  bool _notifyEmail = true;
  bool _notifySms = true;
  bool _notifyPush = true;
  String _alertFrequency = 'Instant';

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<dynamic>('user_profile_box');
    _settingsBox = Hive.box<dynamic>('settings_box');
    _loadData();
  }

  void _loadData() {
    final dynamic raw = _profileBox.get('user_profile');
    if (raw != null) {
      _profile = UserProfileModel.fromJson(Map<String, dynamic>.from(raw));
      _nameCtrl.text = _profile?.name ?? '';
      _cityCtrl.text = _profile?.profileData['city'] ?? '';
    } else {
      _profile = UserProfileModel.empty();
    }

    _notifyEmail = _settingsBox.get('notify_email', defaultValue: true);
    _notifySms = _settingsBox.get('notify_sms', defaultValue: true);
    _notifyPush = _settingsBox.get('notify_push', defaultValue: true);
    _alertFrequency = _settingsBox.get('alert_frequency', defaultValue: 'Instant');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (_profile == null) return;
    setState(() => _isLoading = true);

    try {
      final updatedData = Map<String, dynamic>.from(_profile!.profileData);
      updatedData['city'] = _cityCtrl.text.trim();

      final updatedProfile = _profile!.copyWith(
        name: _nameCtrl.text.trim(),
        profileData: updatedData,
      );

      await _profileBox.put('user_profile', updatedProfile.toJson());

      // Sync to Firestore if Account
      if (updatedProfile.mode == 'account') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await ApiService.registerUser(
            userId: user.uid,
            category: updatedProfile.category,
            name: updatedProfile.name,
            email: updatedProfile.email,
            phone: updatedProfile.phone,
            fcmToken: updatedProfile.fcmToken,
            profileData: updatedData,
          );
        }
      }

      setState(() {
        _profile = updatedProfile;
        _isEditingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: TColors.teal),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: TColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationPref(String key, dynamic value) async {
    await _settingsBox.put(key, value);
    setState(() {
      if (key == 'notify_email') _notifyEmail = value;
      if (key == 'notify_sms') _notifySms = value;
      if (key == 'notify_push') _notifyPush = value;
      if (key == 'alert_frequency') _alertFrequency = value;
    });

    // Sync to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = {
        'notify_email': _notifyEmail,
        'notify_sms': _notifySms,
        'notify_push': _notifyPush,
        'alert_frequency': _alertFrequency,
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'preferences': prefs}, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('settings')
            .set(prefs, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync failed: $e');
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset link sent to ${user.email}'),
              backgroundColor: TColors.primary,
            ),
          );
        }
      } catch (e) {
        _showError('Failed to send reset email: $e');
      }
    }
  }

  Future<void> _clearLocalData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text('Are you sure you want to clear all locally cached intelligence and configuration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: TColors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _profileBox.clear();
      await _settingsBox.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _deleteAccountFlow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account Permanently', style: TextStyle(color: TColors.red, fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete your profile, alerts history and account. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: TColors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // 1. Get current token before deleting the user
        final token = await AuthService.instance.getIdToken();

        // 2. Call Backend API using the token first
        await ApiService.deleteAccount(token: token);

        // 3. Delete Firebase User (handles 'requires-recent-login')
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await user.delete();
          } on FirebaseAuthException catch (authError) {
            if (authError.code == 'requires-recent-login') {
              _showError('Your profile data has been deleted, but for security, deleting your credentials requires a recent login. Please log out, log in again, and retry to complete account deletion.');
              return;
            }
            rethrow;
          }
        }

        // 4. Clear Hive boxes
        await _profileBox.clear();
        await _settingsBox.clear();

        // 5. Sign Out & Onboarding
        await AuthService.instance.signOut();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (_) => false,
          );
        }
      } catch (e) {
        _showError('Failed to delete account: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logoutFlow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out? Your local data will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: TColors.amber),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await AuthService.instance.signOut();
        // Update Hive profile to guest mode
        final dynamic raw = _profileBox.get('user_profile');
        if (raw != null) {
          final map = Map<String, dynamic>.from(raw);
          map['mode'] = 'guest';
          await _profileBox.put('user_profile', map);
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (_) => false,
          );
        }
      } catch (e) {
        _showError('Logout failed: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: TColors.red),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'shop':
        return Icons.store_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'employee':
        return Icons.badge_rounded;
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isGuest = _profile?.mode == 'guest' && FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Settings'.tr(context),
        showBack: true,
      ),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator(color: TColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileSection(),
                const SizedBox(height: 16),
                _buildAppearanceSection(theme, lang),
                if (!isGuest) ...[
                  const SizedBox(height: 16),
                  _buildNotificationsSection(),
                  const SizedBox(height: 16),
                  _buildAccountSection(),
                ],
                if (isGuest) ...[
                  const SizedBox(height: 16),
                  _buildGuestSection(),
                ],
                const SizedBox(height: 16),
                _buildAboutSection(),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ── PROFILE SECTION ───────────────────────
  Widget _buildProfileSection() {
    final category = _profile?.category ?? '';
    final categoryIcon = _getCategoryIcon(category);
    
    final categoryDisplayName = category == 'shop' 
        ? 'Shop Owner'.tr(context) 
        : category == 'business' 
            ? 'Business Owner'.tr(context) 
            : category == 'employee' 
                ? 'Employee'.tr(context) 
                : category == 'student' 
                    ? 'Student'.tr(context) 
                    : 'Not Selected'.tr(context);

    return Container(
      decoration: context.tCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: TColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile?.name ?? 'Guest User'.tr(context), style: context.tHeading3.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${'Category:'.tr(context)} $categoryDisplayName', style: context.tCaption),
                  ],
                ),
              ),
              if (!_isEditingProfile)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: TColors.primary),
                  onPressed: () => setState(() => _isEditingProfile = true),
                ),
            ],
          ),
          if (_isEditingProfile) ...[
            const Divider(height: 24),
            TTextField(
              controller: _nameCtrl,
              label: 'Display Name'.tr(context),
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            TTextField(
              controller: _cityCtrl,
              label: 'City'.tr(context),
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _isEditingProfile = false;
                    _loadData();
                  }),
                  child: Text('Cancel'.tr(context)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfileChanges,
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save'.tr(context)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── APPEARANCE SECTION ────────────────────
  Widget _buildAppearanceSection(ThemeProvider theme, LanguageProvider lang) {
    return Container(
      decoration: context.tCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance'.tr(context), style: context.tHeading3.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined, color: TColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('Theme Mode'.tr(context), style: context.tBodyMd.copyWith(color: context.tTextPrimary))),
              DropdownButton<ThemeMode>(
                value: theme.themeMode,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light'.tr(context))),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark'.tr(context))),
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System'.tr(context))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    theme.setThemeMode(val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.language_rounded, color: TColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('Language'.tr(context), style: context.tBodyMd.copyWith(color: context.tTextPrimary))),
              Switch(
                value: lang.isUrdu,
                activeColor: TColors.primary,
                activeTrackColor: TColors.primaryLight,
                onChanged: (val) {
                  final newLang = val ? 'ur' : 'en';
                  lang.setLanguage(newLang);
                  _settingsBox.put('language', newLang);
                },
              ),
              Text(lang.isUrdu ? 'اردو' : 'English', style: context.tCaption),
            ],
          ),
        ],
      ),
    );
  }

  // ── NOTIFICATIONS SECTION ─────────────────
  Widget _buildNotificationsSection() {
    return Container(
      decoration: context.tCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert Channels'.tr(context), style: context.tHeading3.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          SwitchListTile(
            title: Text('Email alerts'.tr(context)),
            subtitle: Text('Receive analysis reports'.tr(context)),
            secondary: const Icon(Icons.alternate_email_rounded, color: TColors.primary),
            value: _notifyEmail,
            activeColor: TColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _updateNotificationPref('notify_email', val),
          ),
          SwitchListTile(
            title: Text('SMS alerts'.tr(context)),
            subtitle: Text('Receive risk updates via SMS'.tr(context)),
            secondary: const Icon(Icons.sms_rounded, color: TColors.primary),
            value: _notifySms,
            activeColor: TColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _updateNotificationPref('notify_sms', val),
          ),
          SwitchListTile(
            title: Text('Push notifications'.tr(context)),
            subtitle: Text('Get instant device alerts'.tr(context)),
            secondary: const Icon(Icons.notifications_active_rounded, color: TColors.primary),
            value: _notifyPush,
            activeColor: TColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _updateNotificationPref('notify_push', val),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: TColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('Alert Frequency'.tr(context), style: context.tBodyMd.copyWith(color: context.tTextPrimary))),
              DropdownButton<String>(
                value: _alertFrequency,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'Instant', child: Text('Instant'.tr(context))),
                  DropdownMenuItem(value: 'Daily digest', child: Text('Daily digest'.tr(context))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateNotificationPref('alert_frequency', val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ACCOUNT SECTION ───────────────────────
  Widget _buildAccountSection() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      decoration: context.tCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account & Security'.tr(context), style: context.tHeading3.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildReadOnlyField(label: 'Email Address'.tr(context), value: user?.email ?? _profile?.email ?? 'N/A'),
          const SizedBox(height: 12),
          _buildReadOnlyField(label: 'Phone Number'.tr(context), value: _profile?.phone ?? 'N/A'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset_rounded, size: 18),
            label: Text('Change Password'.tr(context)),
            onPressed: _changePassword,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text('Logout'.tr(context)),
            style: OutlinedButton.styleFrom(
              foregroundColor: TColors.amber,
            ),
            onPressed: _logoutFlow,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text('Delete Account'.tr(context)),
            onPressed: _deleteAccountFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── GUEST SECTION ─────────────────────────
  Widget _buildGuestSection() {
    return Container(
      decoration: BoxDecoration(
        color: TColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColors.teal.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.offline_bolt_rounded, color: TColors.tealDark, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upgrade to Account'.tr(context), style: context.tHeading3.copyWith(color: TColors.tealDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Register phone & email to unlock free SMS and email risk alerts.'.tr(context), style: context.tCaption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TPrimaryButton(
            label: 'Create Account'.tr(context),
            icon: Icons.person_add_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text('Clear Local Data'.tr(context)),
            style: OutlinedButton.styleFrom(foregroundColor: TColors.red),
            onPressed: _clearLocalData,
          ),
        ],
      ),
    );
  }

  // ── ABOUT SECTION ─────────────────────────
  Widget _buildAboutSection() {
    return Container(
      decoration: context.tCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About'.tr(context), style: context.tHeading3.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Text('App Version: TadbeerAI v1.0.0'.tr(context), style: context.tBodyMd),
          const SizedBox(height: 8),
          Text('Built for AISeekho2026'.tr(context), style: context.tBodySm),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () => _launchUrl('https://tadbeerai.com/privacy'),
                child: Text('Privacy Policy'.tr(context)),
              ),
              TextButton(
                onPressed: () => _launchUrl('https://tadbeerai.com/terms'),
                child: Text('Terms of Service'.tr(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.tCaption),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.tSurfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          width: double.infinity,
          child: Text(value, style: context.tBody.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}
