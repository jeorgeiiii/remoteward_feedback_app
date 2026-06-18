import 'package:flutter/material.dart';

/// Centralised colour tokens. A single, restrained palette keeps the UI
/// looking intentional rather than templated.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F46E5); // indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF06B6D4); // cyan

  // Surfaces
  static const Color background = Color(0xFFF7F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F1F6);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Feedback
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color border = Color(0xFFE5E7EB);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF7C3AED)],
  );
}
