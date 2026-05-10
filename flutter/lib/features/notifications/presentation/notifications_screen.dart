import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<Map<String, String>> _notifications = [
    {
      'title': 'Practice Reminder',
      'subtitle': 'Your last session was 2 days ago. Keep the streak alive!',
      'time': '1h ago',
    },
    {
      'title': 'New Recitation Tip',
      'subtitle': 'Try the Tajweed feedback mode for faster improvement.',
      'time': '3h ago',
    },
    {
      'title': 'Daily Goal Achieved',
      'subtitle': 'MashaAllah! You completed today’s recitation goal.',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTheme.arabicStyle(
            fontSize: 22,
            isDark: isDark,
          ).copyWith(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.lightTextSecondary
                      : AppColors.darkTextSecondary,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.goldPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.goldDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['subtitle']!,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.lightTextSecondary
                                    : AppColors.darkTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['time']!,
                              style: TextStyle(
                                color: AppColors.goldPrimary.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications have been cleared.'),
            ),
          );
        },
        backgroundColor: AppColors.goldPrimary,
        icon: const Icon(Icons.clear_all_rounded, color: Colors.black),
        label: const Text('Clear All', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}
