import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a hex string to a Flutter Color object.
  /// Supports: #RRGGBB, RRGGBB, #RGB, RGB.
  /// Falls back to [defaultColor] if parsing fails.
  static Color fromHex(String? hexString, {Color defaultColor = const Color(0xFF005147)}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;

    try {
      final buffer = StringBuffer();
      String hex = hexString.replaceFirst('#', '');

      // Handle shorthand #RGB (e.g., #F00 -> #FF0000)
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }

      if (hex.length == 6) {
        buffer.write('ff'); // Default alpha 100%
        buffer.write(hex);
      } else if (hex.length == 8) {
        buffer.write(hex);
      } else {
        return defaultColor;
      }

      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  /// Converts a Color to a Hex string (e.g., #RRGGBB).
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
