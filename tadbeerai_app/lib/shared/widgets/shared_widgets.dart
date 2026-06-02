// lib/shared/widgets/shared_widgets.dart
// Reusable widgets used across all TadbeerAI screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/models/tadbeer_models.dart' show UrgencyLevel;

// ── TOP BAR ──────────────────────────────────
class TTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const TTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.actions,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarColor = TColors.primary; // Matches the brand's primary UI color
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
      decoration: BoxDecoration(
        color: appBarColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title in the center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Back button on the left
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Actions on the right
          if (actions != null)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

// ── STATUS BADGE ─────────────────────────────
class TBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const TBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── URGENCY DOT ──────────────────────────────
class TUrgencyDot extends StatelessWidget {
  final UrgencyLevel urgency;
  final double size;

  const TUrgencyDot({super.key, required this.urgency, this.size = 8});

  Color get _color {
    switch (urgency) {
      case UrgencyLevel.high:
        return TColors.urgencyHigh;
      case UrgencyLevel.medium:
        return TColors.urgencyMed;
      case UrgencyLevel.low:
        return TColors.urgencyLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

// ── SECTION LABEL ────────────────────────────
class TSectionLabel extends StatelessWidget {
  final String label;
  final EdgeInsets? padding;

  const TSectionLabel({super.key, required this.label, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        label.toUpperCase(),
        style: context.tLabel,
      ),
    );
  }
}

// ── LOADING SHIMMER ROW ───────────────────────
class TShimmerCard extends StatelessWidget {
  final double height;
  TShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.tSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ── TEXT FIELD ────────────────────────────────
class TTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  const TTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: context.tBodyMd,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: context.tSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.tBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── STATUS CHIP ─────────────────────────────────
class TStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const TStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── PRIMARY BUTTON ────────────────────────────
class TPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  const TPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? TColors.primary,
          disabledBackgroundColor: TColors.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

// ── CARD WRAPPER ─────────────────────────────
class TCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool hero;

  const TCard(
      {super.key, required this.child, this.padding, this.hero = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(TSpace.md),
      decoration: hero ? context.tCardHero : context.tCard,
      child: child,
    );
  }
}

// ── CARD HEADER ──────────────────────────────
class TCardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const TCardHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: context.tBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          SizedBox(width: 8),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.07 * 11)),
        ],
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────
class TEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  TEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.tTextTertiary),
            SizedBox(height: 16),
            Text(title, style: context.tHeading3, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(subtitle, style: context.tBodyMd, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── THEME TOGGLE BUTTON ──────────────────────
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: () async => await themeProvider.toggleTheme(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.tBorder, width: 0.5),
        ),
        child: Icon(
          themeProvider.isDarkMode
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          size: 18,
          color:
              themeProvider.isDarkMode ? Colors.amber : context.tTextSecondary,
        ),
      ),
    );
  }
}
