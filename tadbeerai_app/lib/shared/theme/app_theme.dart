// lib/shared/theme/app_theme.dart
// TadbeerAI Design System — Team KAARGARAI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
class TColors {
  // Brand
  static const primary = Color(0xFF0066FF); // Royal/Electric Blue
  static const primaryLight = Color(0xFFEAF0FF);
  static const primaryDark = Color(0xFF0A55D1);
  static const primaryDeep = Color(0xFF051126); // Deep Navy

  // Teal / Green (success / done / logo accent green)
  static const teal = Color(0xFF00E676); // Vibrant Lime Green from chart
  static const tealLight = Color(0xFFE8F8F0);
  static const tealDark = Color(0xFF008F47);

  // Amber (impact / warning)
  static const amber = Color(0xFFEF9F27);
  static const amberLight = Color(0xFFFFF3E0);
  static const amberDark = Color(0xFFE65100);

  // Red (urgent / before)
  static const red = Color(0xFFE24B4A);
  static const redLight = Color(0xFFFCEBEB);
  static const redDark = Color(0xFF791F1F);

  // Coral / Cyan (actions / logo glowing cyan)
  static const coral = Color(0xFF00E5FF); // Electric Cyan/Aqua
  static const coralLight = Color(0xFFE0F7FA);
  static const coralDark = Color(0xFF00838F);

  // Neutrals (Light Mode - Tinted Navy/Ice-blue)
  static const bg = Color(0xFFF0F4F8); // Tinted soft ice-blue
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFE2E9F3); // Tinted surface accent
  static const border = Color(0xFFCBD6E2); // Light navy-gray border
  static const borderLight = Color(0xFFEBF0F6);

  // Text (Light Mode - Deep Navy Charcoal)
  static const textPrimary = Color(0xFF0A1128); // Very dark navy text
  static const textSecondary = Color(0xFF3C4D6F); // Medium navy-gray text
  static const textTertiary = Color(0xFF647B9B); // Soft navy text

  // Urgency dots
  static const urgencyHigh = Color(0xFFE24B4A);
  static const urgencyMed = Color(0xFFEF9F27);
  static const urgencyLow = Color(0xFF00E676);

  // Terminal (exec log)
  static const termBg = Color(0xFF020714); // Midnight Navy (from icon)
  static const termText = Color(0xFFE6F0FF);
  static const termOk = Color(0xFF00E676);
  static const termInfo = Color(0xFF00E5FF);
  static const termWarn = Color(0xFFEF9F27);
  static const termError = Color(0xFFE24B4A);
  static const termMuted = Color(0xFF8BA2C0);

  // Dark Mode specific (App Icon Midnight Navy & Glows)
  static const darkBg = Color(0xFF020714); // Midnight Navy background
  static const darkSurface = Color(0xFF081225); // Rich navy card surface
  static const darkSurfaceAlt = Color(0xFF0F203B); // Navy accent surface
  static const darkBorder = Color(0xFF18315B); // Brand navy border
  static const darkTextPrimary = Color(0xFFE6F0FF); // Ice White text
  static const darkTextSecondary =
      Color(0xFF8BA2C0); // Slate navy secondary text
}

// ─────────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────────
class TText {
  static const heading1 = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: TColors.textPrimary,
      letterSpacing: -0.5,
      height: 1.2);
  static const heading2 = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: TColors.textPrimary,
      letterSpacing: -0.3);
  static const heading3 = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: TColors.textPrimary,
      letterSpacing: -0.2);
  static const body =
      TextStyle(fontSize: 14, color: TColors.textPrimary, height: 1.5);
  static const bodyMd =
      TextStyle(fontSize: 13, color: TColors.textSecondary, height: 1.5);
  static const bodySm =
      TextStyle(fontSize: 12, color: TColors.textSecondary, height: 1.5);
  static const caption = TextStyle(fontSize: 11, color: TColors.textTertiary);
  static const label = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: TColors.textTertiary,
      letterSpacing: 0.08 * 11);
  static const mono = TextStyle(
      fontSize: 12, fontFamily: 'monospace', color: TColors.textSecondary);
}

// ─────────────────────────────────────────────
// DECORATIONS
// ─────────────────────────────────────────────
class TDecor {
  static BoxDecoration card = BoxDecoration(
    color: TColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: TColors.border, width: 0.5),
  );

  static BoxDecoration cardHero = BoxDecoration(
    color: TColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: TColors.primary, width: 1.5),
  );

  static BoxDecoration pill(Color bg) => BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      );

  static BoxDecoration chip = BoxDecoration(
    color: TColors.surfaceAlt,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: TColors.border, width: 0.5),
  );
}

// ─────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────
class TSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

// ─────────────────────────────────────────────
// MATERIAL THEME
// ─────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = GoogleFonts.plusJakartaSansTextTheme();
  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primary,
      surface: TColors.bg,
    ),
    scaffoldBackgroundColor: TColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: TColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: TColors.primary,
      labelColor: TColors.primary,
      unselectedLabelColor: TColors.textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TColors.textPrimary,
        side: const BorderSide(color: TColors.border, width: 0.5),
        backgroundColor: TColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: TColors.textTertiary, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

ThemeData buildDarkAppTheme() {
  final base = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primary,
      brightness: Brightness.dark,
      surface: TColors.darkBg,
    ),
    scaffoldBackgroundColor: TColors.darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: TColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: TColors.darkTextPrimary),
      titleTextStyle: TextStyle(
          color: TColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: TColors.primaryLight,
      labelColor: TColors.primaryLight,
      unselectedLabelColor: TColors.darkTextSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TColors.darkTextPrimary,
        side: const BorderSide(color: TColors.darkBorder, width: 0.5),
        backgroundColor: TColors.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TColors.darkSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.darkBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.darkBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TColors.primary, width: 1.5),
      ),
      hintStyle:
          const TextStyle(color: TColors.darkTextSecondary, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

// ─────────────────────────────────────────────
// CONTEXT EXTENSION (FOR DYNAMIC DARK MODE)
// ─────────────────────────────────────────────
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Colors
  Color get tBg => isDark ? TColors.darkBg : TColors.bg;
  Color get tSurface => isDark ? TColors.darkSurface : TColors.surface;
  Color get tSurfaceAlt => isDark ? TColors.darkSurfaceAlt : TColors.surfaceAlt;
  Color get tBorder => isDark ? TColors.darkBorder : TColors.border;
  Color get tBorderLight => isDark ? TColors.darkBorder : TColors.borderLight;
  Color get tTextPrimary =>
      isDark ? TColors.darkTextPrimary : TColors.textPrimary;
  Color get tTextSecondary =>
      isDark ? TColors.darkTextSecondary : TColors.textSecondary;
  Color get tTextTertiary =>
      isDark ? TColors.darkTextSecondary : TColors.textTertiary;

  // Text Styles
  TextStyle get tHeading1 => TText.heading1.copyWith(color: tTextPrimary);
  TextStyle get tHeading2 => TText.heading2.copyWith(color: tTextPrimary);
  TextStyle get tHeading3 => TText.heading3.copyWith(color: tTextPrimary);
  TextStyle get tBody => TText.body.copyWith(color: tTextPrimary);
  TextStyle get tBodyMd => TText.bodyMd.copyWith(color: tTextSecondary);
  TextStyle get tBodySm => TText.bodySm.copyWith(color: tTextSecondary);
  TextStyle get tCaption => TText.caption.copyWith(color: tTextTertiary);
  TextStyle get tLabel => TText.label.copyWith(color: tTextTertiary);
  TextStyle get tMono => TText.mono.copyWith(color: tTextSecondary);

  // Decor
  BoxDecoration get tCard => BoxDecoration(
        color: tSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tBorder, width: 0.5),
      );
  BoxDecoration get tCardHero => BoxDecoration(
        color: tSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TColors.primary, width: 1.5),
      );
  BoxDecoration get tChip => BoxDecoration(
        color: tSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tBorder, width: 0.5),
      );
}
