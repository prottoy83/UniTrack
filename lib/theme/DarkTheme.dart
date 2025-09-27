import 'package:flutter/material.dart';

class DarkTheme {
  // Primary color variations for dark theme
  static const Color primary = Color(0xFF4CAF50); // Brighter green for dark mode
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF2E7D32);
  
  // Base dark color from light theme, used as accent
  static const Color baseDark = Color(0xFF1C352D);
  static const Color baseDarkLight = Color(0xFF2A4A40);
  static const Color baseDarkDark = Color(0xFF0F1F1A);
  
  // Dark surface colors
  static const Color surface = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color surfaceDim = Color(0xFF0A0A0A);
  static const Color surfaceContainer = Color(0xFF1F1F1F);
  static const Color surfaceContainerHigh = Color(0xFF2C2C2C);
  
  // Secondary colors for dark theme
  static const Color secondary = Color(0xFF66BB6A);
  static const Color secondaryLight = Color(0xFF98EE99);
  static const Color secondaryDark = Color(0xFF338A3E);
  
  // Tertiary colors
  static const Color tertiary = Color(0xFFA5D6A7);
  static const Color tertiaryLight = Color(0xFFC8E6C9);
  static const Color tertiaryDark = Color(0xFF81C784);
  
  // Error colors for dark theme
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  
  // Warning colors
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  
  // Success colors
  static const Color success = Color(0xFF66BB6A);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF4CAF50);
  
  // Info colors
  static const Color info = Color(0xFF42A5F5);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF2196F3);
  
  // Text colors for dark theme
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFFB0B0B0);
  static const Color onPrimary = Color(0xFF000000);
  static const Color onSecondary = Color(0xFF000000);
  
  // Background colors
  static const Color background = Color(0xFF0F0F0F);
  static const Color onBackground = Color(0xFFE0E0E0);
  
  // Container colors
  static const Color primaryContainer = Color(0xFF1B5E20);
  static const Color onPrimaryContainer = Color(0xFFC8E6C9);
  static const Color secondaryContainer = Color(0xFF2E7D32);
  static const Color onSecondaryContainer = Color(0xFFA5D6A7);
  
  // Outline colors
  static const Color outline = Color(0xFF404040);
  static const Color outlineVariant = Color(0xFF2A2A2A);
  
  // Surface variant colors
  static const Color surfaceVariant = Color(0xFF1C352D);
  static const Color onSurfaceVariant2 = Color(0xFFB0C4B8);
  
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
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
        tertiaryContainer: baseDark,
        onTertiaryContainer: Color(0xFFA5D6A7),
        error: error,
        onError: onPrimary,
        errorContainer: Color(0xFF4A1F1F),
        onErrorContainer: Color(0xFFFFCDD2),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant2,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE0E0E0),
        onInverseSurface: Color(0xFF121212),
        inversePrimary: baseDark,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainer,
        foregroundColor: onSurface,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceLight,
        shadowColor: Color(0xFF000000).withOpacity(0.3),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
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
        labelStyle: const TextStyle(color: onSurfaceVariant),
        hintStyle: const TextStyle(color: onSurfaceVariant),
      ),
      
      // FloatingActionButton Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        elevation: 8,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: primary,
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
        backgroundColor: surfaceContainerHigh,
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
        backgroundColor: surfaceContainer,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceLight,
        elevation: 16,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 16,
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceContainerHigh,
        contentTextStyle: TextStyle(color: onSurface),
        actionTextColor: primary,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.5);
          }
          return outline;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return onSurfaceVariant;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.3),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(
          color: onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
