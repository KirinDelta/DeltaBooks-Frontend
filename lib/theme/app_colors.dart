import 'package:flutter/material.dart';

/// Delta Deep Water color scheme for the DeltaBooks app
/// A professional, clean, and modern color palette inspired by deep water themes
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  /// Deep Sea Blue - Primary color for app bars, primary actions
  static const Color deepSeaBlue = Color(0xFF1A365D);
  
  /// Delta Teal - Primary text and icons for high contrast
  static const Color deltaTeal = Color(0xFF2D3748);
  
  /// Gold Leaf - Accent color for FAB, ratings, and highlights
  static const Color goldLeaf = Color(0xFFD69E2E);
  
  /// River Mist - Secondary elements, card backgrounds, borders
  static const Color riverMist = Color(0xFFE2E8F0);
  
  /// Very light blue-grey - Scaffold background
  static const Color scaffoldBackground = Color(0xFFF8FAFC);
  
  // Semantic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Text Colors
  static const Color textPrimary = deltaTeal;
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  
  // Border Colors
  static const Color borderLight = riverMist;
  static const Color borderMedium = Color(0xFFCBD5E0);
  static const Color borderDark = Color(0xFFA0AEC0);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepSeaBlue, deltaTeal],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepSeaBlue, Color(0xFF2C5282)],
  );
}
