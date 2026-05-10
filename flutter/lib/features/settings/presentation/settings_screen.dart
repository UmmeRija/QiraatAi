import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/stats_provider.dart';
import '../../../core/utils/toast_helper.dart';
import '../../auth/data/auth_service.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Section Headers: Bold gold uppercase with increased letter spacing.
2. Form Controls: Switches and sliders use the gold primary color (#C9A84C).
3. Profile Section: Gold-accented icons and surface-based tiles.
4. List Items: Modern layout with consistent gold-tinted active elements.
5. Overall Aesthetic: Consistent gold-based theme across all categories.
*/

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _desiAccentSupport = true;
  double _fontSize = 28;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        title: Text(
          "Logout",
          style: TextStyle(
            color: AppColors.goldPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppColors.goldPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Logout",
              style: TextStyle(color: AppColors.mistake),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await ref.read(authServiceProvider).logout();
        if (mounted) {
          ToastHelper.show("Logged out successfully", context: context);
          context.go('/login');
        }
      } catch (e) {
        ToastHelper.show("Error logging out: $e", context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: AppColors.goldPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader("Appearance"),
          _buildCard(
            child: SwitchListTile(
              title: const Text(
                "Dark Mode",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Easier on the eyes for night recitation",
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
              value: isDark,
              activeColor: AppColors.goldPrimary,
              activeTrackColor: AppColors.goldPrimary.withOpacity(0.3),
              onChanged: (val) =>
                  ref.read(themeProvider.notifier).toggleTheme(val),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("Recitation Engine"),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "Desi Accent Support",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Optimized for South Asian pronunciation quirks",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: _desiAccentSupport,
                  activeColor: AppColors.goldPrimary,
                  activeTrackColor: AppColors.goldPrimary.withOpacity(0.3),
                  onChanged: (val) => setState(() => _desiAccentSupport = val),
                ),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  indent: 16,
                  endIndent: 16,
                ),
                const ListTile(
                  title: Text(
                    "Arabic Font Size",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Slider(
                    value: _fontSize,
                    min: 24,
                    max: 48,
                    activeColor: AppColors.goldPrimary,
                    inactiveColor: isDark
                        ? AppColors.darkBorder
                        : Colors.grey[200],
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("Account"),
          _buildCard(
            child: ref
                .watch(statsProvider)
                .when(
                  data: (stats) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                    title: const Text(
                      "Reciter Profile",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${stats['total_sessions'] ?? 0} Sessions Completed",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.goldPrimary,
                    ),
                    onTap: () => context.push('/profile'),
                  ),
                  loading: () =>
                      const ListTile(title: Text("Loading profile...")),
                  error: (_, __) =>
                      const ListTile(title: Text("Reciter Profile")),
                ),
          ),

          const SizedBox(height: 12),
          _buildCard(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mistake.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.mistake,
                ),
              ),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: AppColors.mistake,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _handleLogout,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}
