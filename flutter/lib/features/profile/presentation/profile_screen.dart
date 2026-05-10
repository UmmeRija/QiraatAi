import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/stats_provider.dart';
import '../../auth/data/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState?['user'] as Map<String, dynamic>?;
    final fullName = user?['full_name'] as String? ?? 'Guest Reciter';
    final email = user?['email'] as String? ?? 'No email available';
    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((part) => part[0]).take(2).join()
        : 'GR';
    final statsAsync = ref.watch(statsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTheme.arabicStyle(
            fontSize: 22,
            isDark: isDark,
          ).copyWith(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.goldPrimary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.goldDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.lightTextSecondary
                              : AppColors.darkTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recitation Summary',
            style: const TextStyle(
              color: AppColors.goldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoTile(
                  context,
                  label: 'Sessions',
                  value: '${stats['total_sessions'] ?? 0}',
                ),
                _buildInfoTile(
                  context,
                  label: 'Accuracy',
                  value:
                      '${(((stats['average_accuracy'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}%',
                ),
                _buildInfoTile(
                  context,
                  label: 'Streak',
                  value: '${stats['streak'] ?? 0}d',
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              'Could not load stats',
              style: TextStyle(color: AppColors.mistake),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Account Actions'),
          const SizedBox(height: 12),
          _buildActionTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your name or account details',
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            context,
            icon: Icons.settings_rounded,
            title: 'App Settings',
            subtitle: 'Change theme and preferences',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.goldDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.lightTextSecondary
                    : AppColors.darkTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.goldPrimary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.goldPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.goldDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppColors.lightTextSecondary
                : AppColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.goldPrimary,
        ),
        onTap: onTap,
      ),
    );
  }
}
