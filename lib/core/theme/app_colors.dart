import 'package:flutter/material.dart';

/// RYVE Silent Wealth Architecture — Design Tokens: Colors
/// Light-first, warm off-white background, crisp white surfaces, dark charcoal typography,
/// and restrained muted semantic indicators.
abstract class AppColors {
  // Background & Surfaces
  static const Color background = Color(0xFFF8F9FB); // Clean, airy off-white
  static const Color surface = Color(0xFFFFFFFF); // Crisp pure white cards
  static const Color surfaceElevated = Color(0xFFF1F3F7); // Soft light elevated container
  static const Color surfaceHover = Color(0xFFE5E7EB);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE9ECEF); // Soft minimalist border
  static const Color borderMedium = Color(0xFFD1D5DB);

  // Typography (Charcoal & Slates)
  static const Color textPrimary = Color(0xFF0F172A); // Deep slate charcoal
  static const Color textSecondary = Color(0xFF475569); // Refined slate gray
  static const Color textDisabled = Color(0xFF94A3B8); // Subtle placeholder slate
  static const Color textOnDark = Color(0xFFFFFFFF); // Crisp white text

  // Brand Accents & Gradients
  static const Color primary = Color(0xFF4F46E5); // Modern Electric Indigo
  static const Color primaryLight = Color(0xFFEEF2FF); // Soft Indigo Tint
  static const Color accent = Color(0xFF0F172A);
  static const Color accentSubtle = Color(0xFFF1F5F9);

  // Tasteful Vibrant Semantic Indicators
  static const Color income = Color(0xFF10B981); // Vibrant Emerald Mint
  static const Color incomeLight = Color(0xFFECFDF5); // Soft Mint Tint

  static const Color expense = Color(0xFFF43F5E); // Warm Sunset Rose/Coral
  static const Color expenseLight = Color(0xFFFFF1F2); // Soft Rose Tint

  static const Color lent = Color(0xFF0EA5E9); // Electric Cyan Sky
  static const Color lentLight = Color(0xFFF0F9FF); // Soft Sky Tint

  static const Color borrowed = Color(0xFF8B5CF6); // Royal Violet
  static const Color borrowedLight = Color(0xFFF5F3FF); // Soft Violet Tint

  static const Color warning = Color(0xFFF59E0B); // Warm Golden Amber
  static const Color warningLight = Color(0xFFFFFBEB); // Soft Amber Tint

  // Account Type Colors
  static const Color bankColor = Color(0xFF4F46E5);
  static const Color upiColor = Color(0xFF8B5CF6);
  static const Color cashColor = Color(0xFF10B981);
  static const Color onlineColor = Color(0xFF0EA5E9);
  static const Color cardColor = Color(0xFFF59E0B);
  static const Color otherColor = Color(0xFF0EA5E9);

  // Category Color Palette
  static const List<Color> categoryPalette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF0EA5E9), // Cyan
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  // Soft Box Shadows for Minimal Depth
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

