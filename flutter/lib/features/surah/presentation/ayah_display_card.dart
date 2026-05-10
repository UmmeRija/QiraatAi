import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class AyahDisplayCard extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String urduTranslation;
  final bool isLoading;

  const AyahDisplayCard({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.urduTranslation,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildShimmer(isDark);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAyahBadge(isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  arabicText,
                  style: AppTheme.arabicStyle(
                    fontSize: 28,
                    isDark: isDark,
                    color: isDark ? AppColors.darkArabicText : AppColors.lightArabicText,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Text(
                  urduTranslation,
                  style: TextStyle(
                    color: AppColors.goldPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAyahBadge(bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        ayahNumber.toString(),
        style: TextStyle(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 28,
                  width: double.infinity,
                  color: Colors.grey.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                Container(
                  height: 15,
                  width: double.infinity,
                  color: Colors.grey.withOpacity(0.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}