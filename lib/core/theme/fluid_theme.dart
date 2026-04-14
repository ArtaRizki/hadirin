import 'package:flutter/material.dart';

class FluidColors {
  final Color primary;
  static const Color background = Color(0xFFF9F9F8);
  static const Color surface = Color(0xFFF9F9F8);
  static const Color surfaceContainerLow = Color(0xFFF3F4F3);
  static const Color onSurface = Color(0xFF1A1C1A);

  Color get primaryGhost => primary.withOpacity(0.2);

  FluidColors({required this.primary});
}

/// 2. SHAPE & RADIUS (Sesuai panduan Nested Radius)
class FluidRadii {
  static const double md = 24.0;
  static const double sm = 8.0;
}

/// 3. SPACING (Pengganti Divider)
class FluidSpacing {
  static const double section = 40.0;
}

/// 4. THEME DATA UTAMA
class FluidTheme {
  static ThemeData getTheme(Color primaryColor) {
    final colors = FluidColors(primary: primaryColor);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: FluidColors.background,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        surface: FluidColors.surface,
        onSurface: FluidColors.onSurface,
        surfaceContainerHighest: FluidColors.surfaceContainerLow,
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: FluidSpacing.section,
        thickness: 0,
      ),

      cardTheme: CardThemeData(
        color: FluidColors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluidRadii.md),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FluidColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
          borderSide: BorderSide(
            color: colors.primaryGhost,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}

extension FluidThemeExtension on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get primaryGhost => primaryColor.withOpacity(0.2);
}
