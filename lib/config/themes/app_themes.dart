import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constant/app_colors.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito Sans',
    textTheme: GoogleFonts.nunitoSansTextTheme(
      const TextTheme(
        // Course titles, main headings
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.heading,
          letterSpacing: -0.5,
        ),
        // Section headings
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
        // Subsection headings
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
        // Course description, important content
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        // Lesson titles, card headings
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        // Secondary information
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),

        // Main content text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        // Regular content, descriptions
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        // Captions, metadata
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.gray600,
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    splashColor: AppColors.surface,

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.gray600,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      color: AppColors.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.gray900),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.heading,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primary),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.failure),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    textTheme: GoogleFonts.hankenGroteskTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.gray100,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.gray100,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.gray200,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.gray100,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.gray200,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.gray300,
          height: 1.4,
        ),
      ),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: AppColors.black,

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.gray400,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      color: AppColors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primary),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.gray800,
      surfaceTintColor: AppColors.gray800,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.gray800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gray600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gray600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.failure),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
