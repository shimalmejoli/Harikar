// lib/core/app_theme.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for all visual design tokens.
// Import this in every screen instead of hardcoding colors.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colors ────────────────────────────────────────────
  static const Color primary = Color(0xFF5C35CC);
  static const Color primaryDark = Color(0xFF4527A0);
  static const Color accent = Color(0xFF2979FF);
  static const Color background = Color(0xFFF2F3F7);
  static const Color cardBlue = Color(0xFF6B8FD4);
  static const Color cardLight = Color(0xFF93B0E0);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  // Neutral palette
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A5A6E);
  static const Color textMuted = Color(0xFF8C8CA1);
  static const Color divider = Color(0xFFE6E7EE);

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFFFF9800)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBlue, cardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient loadingGradient = LinearGradient(
    colors: [Colors.white, Color(0x102979FF), Color(0x085C35CC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Spacing scale ───────────────────────────────────────────
  static const double space2 = 4.0;
  static const double space3 = 8.0;
  static const double space4 = 12.0;
  static const double space5 = 16.0;
  static const double space6 = 20.0;
  static const double space7 = 24.0;
  static const double space8 = 32.0;

  // ── Border radius ───────────────────────────────────────────
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ── Sizing ──────────────────────────────────────────────────
  static const double appBarHeight = 56.0;
  static const double buttonHeight = 50.0;
  static const double inputHeight = 52.0;
  static const double touchTarget = 48.0;

  // ── Text styles ─────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 14,
    color: Colors.black87,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 12,
    color: Colors.black54,
    height: 1.4,
  );

  static const TextStyle labelWhite = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle captionWhite = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 11,
    color: Colors.white70,
    height: 1.4,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'NotoKufi',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 1.1,
  );

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: cardBlue.withOpacity(0.30),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> appBarShadow = [
    BoxShadow(
      color: primary.withOpacity(0.20),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

  // ── Material theme ───────────────────────────────────────────
  static ThemeData get theme {
    final base = ThemeData(
      fontFamily: 'NotoKufi',
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        error: error,
        surface: surface,
      ),
    );

    return base.copyWith(
      // AppBar — gradient is applied per-screen via BrandedAppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: headingLarge,
        iconTheme: IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 22),
        centerTitle: true,
        titleSpacing: 0,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        color: surface,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          color: Colors.white,
          fontSize: 13,
        ),
      ),

      // Inputs (TextField, DropdownButtonFormField, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 13,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 13,
          color: textMuted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 13,
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: primary,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 11,
          color: error,
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoKufi',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.4),
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoKufi',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoKufi',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
      ),

      // Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withOpacity(0.12),
        labelStyle: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 12,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
    );
  }
}
