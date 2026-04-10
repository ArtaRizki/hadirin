import 'package:flutter/material.dart';

/// 1. COLOR PALETTE (Sesuai panduan Tonal Layering)
class FluidColors {
  static const Color primary = Color(0xFF005147); // Emerald Green
  static const Color background = Color(0xFFF9F9F8); // Tinted neutral "warm"
  static const Color surface = Color(0xFFF9F9F8);
  static const Color surfaceContainerLow = Color(0xFFF3F4F3);
  static const Color onSurface = Color(
    0xFF1A1C1A,
  ); // Hindari pure black #000000
  static const Color primaryGhost = Color(
    0x33005147,
  ); // Primary dengan 20% opacity
}

/// 2. SHAPE & RADIUS (Sesuai panduan Nested Radius)
class FluidRadii {
  static const double md = 24.0; // Outer containers (Cards, BottomSheets)
  static const double sm = 8.0; // Inner elements (Inputs, Buttons)
}

/// 3. SPACING (Pengganti Divider)
class FluidSpacing {
  static const double section =
      40.0; // Gunakan ruang kosong 32px-48px sebagai pemisah
}

/// 4. THEME DATA UTAMA
class FluidTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: FluidColors.background,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: FluidColors.primary,
        surface: FluidColors.surface,
        onSurface: FluidColors.onSurface,
        surfaceContainerHighest:
            FluidColors.surfaceContainerLow, // Mapping warna layer
      ),

      // FORBIDDEN DIVIDERS: Membuat divider menjadi transparan secara global
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: FluidSpacing.section,
        thickness: 0,
      ),

      // CARDS (Outer Container): Tanpa border, radius 24px, warna layer terpisah
      cardTheme: CardThemeData(
        color: FluidColors.surfaceContainerLow,
        elevation: 0, // No shadow, pure tonal shift
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluidRadii.md),
        ),
      ),

      // INPUT FIELDS (Inner Element): Radius 8px, Ghost Border saat Focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FluidColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // Default State: Tanpa border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: BorderSide.none,
        ),
        // Focus State: Primary Ghost Border (2px, 20% opacity)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: const BorderSide(
            color: FluidColors.primaryGhost,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
