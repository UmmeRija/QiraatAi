import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../theme/app_colors.dart';

// Animation only — logic unchanged
/*
Visual changes:
1. Implemented CurvedNavigationBar as seen in the requested tutorial.
2. Background color transitions smoothly between the nav bar and screen.
3. Centered gold primary button with smooth liquid-like motion.
4. Simplified icons for the liquid transition aesthetic.
5. Adjusted height to 60px for a sleek profile.
*/

class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background of the nav bar should match the Scaffold background
    final scaffoldBg = isDark ? AppColors.darkBg : AppColors.lightBg;
    // Color of the actual nav bar body
    final navBarBodyColor = isDark ? AppColors.darkBottomNav : AppColors.lightBottomNav;

    return Container(
      color: scaffoldBg, // This ensures the curve looks perfect
      child: CurvedNavigationBar(
        index: currentIndex,
        height: 60,
        items: <Widget>[
          Icon(
            Icons.home_rounded, 
            size: 26, 
            color: currentIndex == 0 ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          Icon(
            Icons.menu_book_rounded, 
            size: 26, 
            color: currentIndex == 1 ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          Icon(
            Icons.bar_chart_rounded, 
            size: 26, 
            color: currentIndex == 2 ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          Icon(
            Icons.mosque_rounded, 
            size: 26, 
            color: currentIndex == 3 ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          Icon(
            Icons.settings_rounded, 
            size: 26, 
            color: currentIndex == 4 ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ],
        color: navBarBodyColor,
        buttonBackgroundColor: AppColors.goldPrimary,
        backgroundColor: scaffoldBg,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: onTap,
        letIndexChange: (index) => true,
      ),
    );
  }
}