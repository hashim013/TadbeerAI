import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:tadbeerai/core/models/user_profile_model.dart';
import 'package:tadbeerai/core/providers/language_provider.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';
import 'profile_form_screen.dart';

class CategorySelectorScreen extends StatelessWidget {
  const CategorySelectorScreen({super.key});

  Future<void> _selectCategory(BuildContext context, String category) async {
    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final dynamic raw = box.get('user_profile');
      UserProfileModel profile;
      if (raw != null) {
        profile = UserProfileModel.fromJson(Map<String, dynamic>.from(raw)).copyWith(category: category);
      } else {
        profile = UserProfileModel.empty().copyWith(category: category);
      }
      await box.put('user_profile', profile.toJson());
    } catch (e) {
      debugPrint('Error saving category: $e');
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileFormScreen(category: category),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Select Your Persona'.tr(context),
        showBack: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Help TadbeerAI tailor its intelligence feed to your personal situation.'.tr(context),
                textAlign: TextAlign.center,
                style: context.tBodyMd,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildCategoryCard(
                      context,
                      category: 'shop',
                      icon: Icons.store_rounded,
                      title: 'Shop Owner'.tr(context),
                      subtitle: 'Retail, inventory, and monthly shop revenues.'.tr(context),
                      color: TColors.primary,
                      index: 0,
                    ),
                    _buildCategoryCard(
                      context,
                      category: 'business',
                      icon: Icons.business_rounded,
                      title: 'Business Owner'.tr(context),
                      subtitle: 'Turnover, employee count, and industry growth.'.tr(context),
                      color: TColors.teal,
                      index: 1,
                    ),
                    _buildCategoryCard(
                      context,
                      category: 'employee',
                      icon: Icons.badge_rounded,
                      title: 'Employee'.tr(context),
                      subtitle: 'Salaried sectors, company sizes, and income.'.tr(context),
                      color: TColors.amber,
                      index: 2,
                    ),
                    _buildCategoryCard(
                      context,
                      category: 'student',
                      icon: Icons.school_rounded,
                      title: 'Student'.tr(context),
                      subtitle: 'University research, fields of study, and stipends.'.tr(context),
                      color: TColors.coral,
                      index: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String category,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _selectCategory(context, category),
      child: Container(
        decoration: BoxDecoration(
          color: context.tSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.tBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: context.tHeading3.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.tCaption.copyWith(
                  height: 1.3,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).scale(delay: Duration(milliseconds: index * 100), begin: const Offset(0.9, 0.9));
  }
}
