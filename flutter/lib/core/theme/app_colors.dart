import 'package:flutter/material.dart';

class AppColors {
  // Theme updated — logic unchanged

  // Gold / Brand Colors
  static const Color goldPrimary = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE2C97E);
  static const Color goldDark = Color(0xFF8B6914);
  
  // Semantic colors
  static const Color correct = Color(0xFF5DBE6A);
  static const Color mistake = Color(0xFFE05555);
  static const Color warning = Color(0xFFE8A020);
  static const Color recordActive = Color(0xFFE05555);
  static const Color recordIdle = Color(0xFFC9A84C);

  // Dark Mode
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF161616);
  static const Color darkCardElevated = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkBottomNav = Color(0xFF111111);
  static const Color darkGoldTintBg = Color(0xFF1E1A0F);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFF8A8A8A);
  static const Color darkTextHint = Color(0xFF555555);
  static const Color darkArabicText = Color(0xFFEEECE4);

  // Light Mode
  static const Color lightBg = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2DDD0);
  static const Color lightBottomNav = Color(0xFFEDE8DC);
  static const Color lightGoldTintBg = Color(0xFFFBF6E9);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF888070);
  static const Color lightTextHint = Color(0xFFAAA090);
  static const Color lightArabicText = Color(0xFF1A1A1A);

  // Legacy mappings for minimal breaking changes if any
  static const Color primaryBrand = goldPrimary;
  static const Color errorRed = mistake;
  static const Color successGreen = correct;
}
