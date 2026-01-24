import 'package:flutter/material.dart';

class AppColors {
  /// Primary and Secondary colors
  static const Color primary = Color(0xFF1C3B5A); // Deep blue
  static const Color secondary = Color(0xFF2A5D9F); // Medium blue

  /// Text colors - adjusted to complement primary
  static const Color heading = Color(0xFF1A324D); // Darker variant of primary
  static const Color text = Color(0xFF4A5B6E); // Muted blue-grey

  /// Border color - slightly blue tinted
  static const Color border = Color(0xFFD8E1E9); // Light blue-grey

  /// Background colors - with subtle blue undertones
  static const Color lightGreyBg = Color(0xFFF8FAFC); // Very light blue-grey
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color card = Color(0xFFF5F8FA); // Light blue-grey
  static const Color scaffoldBackground = Color(0xFFF0F4F8); // Light blue-grey

  /// Status colors - adjusted to match the palette
  static const Color success = Color(0xFF2E7D32); // Forest green
  static const Color failure = Color(0xFFD32F2F); // Deep red
  static const Color warning = Color(0xFFF9A825); // Deep amber
  static const Color info = Color(0xFF2A5D9F); // Using secondary color

  /// Grayscale colors - with slight blue undertones
  static const Color gray900 = Color(0xFF1A2632); // Very dark blue-grey
  static const Color gray800 = Color(0xFF2D3B47); // Dark blue-grey
  static const Color gray700 = Color(0xFF3D4D5C); // Medium-dark blue-grey
  static const Color gray600 = Color(0xFF556575); // Medium blue-grey
  static const Color gray500 = Color(0xFF7B8A99); // Medium blue-grey
  static const Color gray400 = Color(0xFFA3AEB9); // Light blue-grey
  static const Color gray300 = Color(0xFFCFD6DE); // Lighter blue-grey
  static const Color gray200 = Color(0xFFE2E8ED); // Very light blue-grey
  static const Color gray100 = Color(0xFFF0F4F8); // Extremely light blue-grey

  /// Utility colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color shadowColor = Color(0x1A1C3B5A); // Primary-based shadow


  ///Quiz
  static const Color quizColor =
  Color(0xBBDEFBFF);
  /// Accent colors
  static const Color accent = secondary; // Using secondary as accent
  static const Color highlight =
      Color(0xFF3D7CC9); // Lighter version of secondary

  /// Divider color
  static const Color divider = Color(0xFFE2E8ED); // Light blue-grey

  /// Opacity variations
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);

  static Color successWithOpacity(double opacity) =>
      success.withOpacity(opacity);

  static Color failureWithOpacity(double opacity) =>
      failure.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);

  /// Gradients
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [lightGreyBg, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Additional gradients that complement the primary/secondary colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF2A5D9F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF3D7CC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}
