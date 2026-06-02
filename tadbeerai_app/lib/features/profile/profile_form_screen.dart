import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:tadbeerai/core/models/user_profile_model.dart';
import 'package:tadbeerai/core/providers/language_provider.dart';
import 'package:tadbeerai/core/services/api_service.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';
import '../home/home_screen.dart';

class ProfileFormScreen extends StatefulWidget {
  final String category;

  const ProfileFormScreen({super.key, required this.category});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final fields = _getFieldsForCategory(widget.category);
    for (var f in fields) {
      _controllers[f['key']!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<Map<String, String>> _getFieldsForCategory(String category) {
    switch (category) {
      case 'shop':
        return [
          {
            'key': 'shop_type',
            'label': 'Shop Type (e.g. Grocery, Retail)',
            'icon': 'store'
          },
          {'key': 'city', 'label': 'City', 'icon': 'location_on'},
          {
            'key': 'monthly_revenue',
            'label': 'Monthly Revenue (PKR)',
            'icon': 'payments'
          },
          {
            'key': 'inventory_size',
            'label': 'Inventory Size (Items Count)',
            'icon': 'inventory_2'
          },
        ];
      case 'business':
        return [
          {
            'key': 'industry',
            'label': 'Industry (e.g. IT, Manufacturing)',
            'icon': 'domain'
          },
          {'key': 'city', 'label': 'City', 'icon': 'location_on'},
          {
            'key': 'monthly_turnover',
            'label': 'Monthly Turnover (PKR)',
            'icon': 'bar_chart'
          },
          {
            'key': 'employee_count',
            'label': 'Employee Count',
            'icon': 'groups'
          },
        ];
      case 'employee':
        return [
          {
            'key': 'salary_range',
            'label': 'Monthly Salary Range (PKR)',
            'icon': 'payments'
          },
          {
            'key': 'sector',
            'label': 'Sector (e.g. Private, Public)',
            'icon': 'badge'
          },
          {
            'key': 'company_size',
            'label': 'Company Size (Employees)',
            'icon': 'corporate_fare'
          },
          {'key': 'city', 'label': 'City', 'icon': 'location_on'},
        ];
      case 'student':
        return [
          {'key': 'university', 'label': 'University Name', 'icon': 'school'},
          {
            'key': 'field_of_study',
            'label': 'Field of Study (e.g. CS, Eng)',
            'icon': 'menu_book'
          },
          {
            'key': 'stipend',
            'label': 'Monthly Stipend (PKR)',
            'icon': 'payments'
          },
          {'key': 'city', 'label': 'City', 'icon': 'location_on'},
        ];
      default:
        return [];
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'store':
        return Icons.store_rounded;
      case 'location_on':
        return Icons.location_on_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'domain':
        return Icons.domain_rounded;
      case 'bar_chart':
        return Icons.bar_chart_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'corporate_fare':
        return Icons.corporate_fare_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  TextInputType _getKeyboardType(String key) {
    if (key == 'monthly_revenue' ||
        key == 'inventory_size' ||
        key == 'monthly_turnover' ||
        key == 'employee_count' ||
        key == 'company_size' ||
        key == 'stipend') {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final dynamic raw = box.get('user_profile');

      UserProfileModel profile;
      if (raw != null) {
        profile = UserProfileModel.fromJson(Map<String, dynamic>.from(raw));
      } else {
        profile = UserProfileModel.empty();
      }

      // Collect profile data map
      final Map<String, dynamic> data = {};
      _controllers.forEach((key, ctrl) {
        data[key] = ctrl.text.trim();
      });

      final updatedProfile = profile.copyWith(
        category: widget.category,
        profileData: data,
      );

      // Save locally
      await box.put('user_profile', updatedProfile.toJson());

      // If account mode, sync with backend
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && updatedProfile.mode == 'account') {
        await ApiService.registerUser(
          userId: user.uid,
          category: widget.category,
          name: updatedProfile.name,
          email: updatedProfile.email,
          phone: updatedProfile.phone,
          fcmToken: updatedProfile.fcmToken,
          profileData: data,
        );
        debugPrint('Firestore profile synced on backend.');
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: TColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _getFieldsForCategory(widget.category);
    final categoryLabel =
        widget.category[0].toUpperCase() + widget.category.substring(1);

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: '${categoryLabel} Information'.tr(context),
        showBack: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              Text(
                'Complete details below to analyze your specific business risk and action recommendations.'.tr(context),
                style: context.tBodyMd,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              ...fields.map((f) {
                final key = f['key']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TTextField(
                    controller: _controllers[key]!,
                    label: f['label']!.tr(context),
                    icon: _getIconData(f['icon']!),
                    keyboardType: _getKeyboardType(key),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'This field is required'.tr(context)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 24),
              TPrimaryButton(
                label: 'Save & Proceed'.tr(context),
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onTap: _saveForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
