import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Applied full dark background #0D0D0D.
2. Centered gold Arabic calligraphy logo with fade-in and scale animation.
3. Added soft gold ring pulse animation around the logo.
4. Implemented subtle gold shimmer on the logo.
5. Updated typography to use Gold primary for headings.
*/

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _navigateToHome();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/home'); // GoRouter will redirect to /login if not authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Rings
                ...List.generate(2, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      double progress = (_pulseController.value + (index * 0.5)) % 1.0;
                      return Container(
                        width: 140 + (progress * 100),
                        height: 140 + (progress * 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldPrimary.withOpacity(1.0 - progress),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  );
                }),
                
                // Logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140, // Slightly larger for better impact
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack)
                    .shimmer(delay: 1500.ms, duration: 2000.ms, color: AppColors.goldLight),
              ],
            ),
            
            const SizedBox(height: 48),
            
            Text(
              "QiraatAI",
              style: AppTheme.arabicStyle(fontSize: 36, isDark: true).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.goldPrimary,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 800.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
            
            const SizedBox(height: 12),
            
            Text(
              "Elevating Your Recitation",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    letterSpacing: 3,
                  ),
            ).animate().fadeIn(delay: 1600.ms, duration: 800.ms).moveY(begin: 10, end: 0),
          ],
        ),
      ),
    );
  }
}
