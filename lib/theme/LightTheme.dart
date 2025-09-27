import 'package:flutter/material.dart';

class LightTheme {
  // Primary color #1C352D and its variations
  static const Color primary = Color(0xFF1C352D);
  static const Color primaryLight = Color(0xFF2A4A40);
  static const Color primaryDark = Color(0xFF0F1F1A);
  
  // Monotone light variations
  static const Color surface = Color(0xFFF8FAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F3F2);
  
  // Complementary shades (not monotone)
  static const Color secondary = Color(0xFF4A7C59);
  static const Color secondaryLight = Color(0xFF6B9C7A);
  static const Color secondaryDark = Color(0xFF2E5A3B);
  
  // Accent colors
  static const Color tertiary = Color(0xFF8FA68F);
  static const Color tertiaryLight = Color(0xFFB5C9B5);
  static const Color tertiaryDark = Color(0xFF6B846B);
  
  // Error colors
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFC62828);
  
  // Warning colors
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFE65100);
  
  // Success colors
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color successDark = Color(0xFF2E7D32);
  
  // Info colors
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1565C0);
  
  // Text colors
  static const Color onSurface = Color(0xFF1C352D);
  static const Color onSurfaceVariant = Color(0xFF4A4A4A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // Background colors
  static const Color background = Color(0xFFFCFEFD);
  static const Color onBackground = Color(0xFF1C352D);
  
  // Container colors
  static const Color primaryContainer = Color(0xFFE8F3F0);
  static const Color onPrimaryContainer = Color(0xFF0F1F1A);
  static const Color secondaryContainer = Color(0xFFE8F5EA);
  static const Color onSecondaryContainer = Color(0xFF2E5A3B);
  
  // Outline colors
  static const Color outline = Color(0xFFCAD0CD);
  static const Color outlineVariant = Color(0xFFE0E6E3);
  
  // Surface variant colors
  static const Color surfaceVariant = Color(0xFFE8F3F0);
  static const Color onSurfaceVariant2 = Color(0xFF5A635F);
  
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onPrimary,
        tertiaryContainer: Color(0xFFE8F3F0),
        onTertiaryContainer: onPrimaryContainer,
        error: error,
        onError: onPrimary,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: errorDark,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant2,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: primaryDark,
        onInverseSurface: surfaceLight,
        inversePrimary: Color(0xFFA8D5C8),
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        shadowColor: primary.withOpacity(0.1),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1C352D),
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // FloatingActionButton Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        elevation: 6,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: onPrimary,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryContainer,
        disabledColor: surfaceDim,
        labelStyle: const TextStyle(color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
