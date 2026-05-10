import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/stats_provider.dart';
import '../../../core/providers/prayer_provider.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Progress Cards: Dark surface (#161616) and gold accents (#C9A84C).
2. Charts: Learning velocity chart features gold bars with rounded corners.
3. Achievements: Redesigned with gold-tinted circular badges.
4. Recent Activity: Sessions display accuracy in gold circular indicators.
5. Overall Aesthetic: Gold-based theme with staggered animations for all sections.
*/

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(statsProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final contentPadding = EdgeInsets.fromLTRB(
      24,
      24,
      24,
      12 + 60 + bottomInset,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          "Your Journey",
          style: TextStyle(
            color: AppColors.goldPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(statsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallProgressCard(context, isDark, stats),
                const SizedBox(height: 32),
                _buildPrayerProgressCard(context, ref, isDark),
                const SizedBox(height: 40),

                Text(
                  "Learning Velocity",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),
                _buildSpeedChart(
                  context,
                  isDark,
                  (stats['weekly_progress'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
                ),

                const SizedBox(height: 40),
                Text(
                  "Achievements",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),
                _buildAchievementGrid(isDark, stats['streak'] ?? 0),

                const SizedBox(height: 40),
                Text(
                  "Recent Activity",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 16),
                _buildRecentActivity(context, isDark, ref),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.mistake, size: 48),
              const SizedBox(height: 16),
              Text(
                "Failed to load progress",
                style: TextStyle(color: AppColors.goldPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(statsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> stats,
  ) {
    final avgAccuracyNum = stats['average_accuracy'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLargeStat(
                stats['total_words']?.toString() ?? "0",
                "Words Read",
              ),
              _divider(isDark),
              _buildLargeStat(
                "${(avgAccuracyNum * 100).toInt()}%",
                "Avg Accuracy",
              ),
              _divider(isDark),
              _buildLargeStat(
                stats['total_surahs']?.toString() ?? "0",
                "Surahs",
              ),
            ],
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (stats['total_surahs'] ?? 0) / 114,
              backgroundColor: isDark ? AppColors.darkBorder : Colors.grey[200],
              color: AppColors.goldPrimary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Quran Completion",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                "${((stats['total_surahs'] ?? 0) / 114 * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  Widget _divider(bool isDark) => Container(
    height: 30,
    width: 1,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );

  Widget _buildLargeStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.goldPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedChart(
    BuildContext context,
    bool isDark,
    List<double> weeklyProgress,
  ) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        days[value.toInt()],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyProgress.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value * 100,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldPrimary, AppColors.goldLight],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildAchievementGrid(bool isDark, int streak) {
    final achievements = [
      {
        "icon": Icons.workspace_premium_rounded,
        "label": "Early Bird",
        "unlocked": true,
      },
      {
        "icon": Icons.auto_awesome_rounded,
        "label": "Perfect",
        "unlocked": streak > 0,
      },
      {
        "icon": Icons.bolt_rounded,
        "label": "Fast Learner",
        "unlocked": streak > 3,
      },
      {
        "icon": Icons.favorite_rounded,
        "label": "Dedicated",
        "unlocked": streak > 7,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: achievements.map((a) {
        final unlocked = a['unlocked'] as bool;
        return Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.goldPrimary.withOpacity(0.1)
                    : (isDark ? Colors.white10 : Colors.grey[100]),
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked
                      ? AppColors.goldPrimary.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                a['icon'] as IconData,
                color: unlocked
                    ? AppColors.goldPrimary
                    : (isDark ? Colors.white24 : Colors.grey[400]),
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              a['label'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: unlocked
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : Colors.grey,
              ),
            ),
          ],
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildRecentActivity(
    BuildContext context,
    bool isDark,
    WidgetRef ref,
  ) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                "Start your recitation today!",
                style: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length > 5 ? 5 : sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = sessions[index];
            final DateTime time = DateTime.parse(s['timestamp']);
            final accuracyNum = s['accuracy_score'] as num? ?? 0;
            final accuracy = (accuracyNum * 100).toInt();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.goldPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "$accuracy%",
                        style: const TextStyle(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['surah_name'] ?? "Surah ${s['surah_id']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "${time.day}/${time.month}/${time.year} • Session Complete",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.goldPrimary,
                    size: 14,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      ),
      error: (e, s) => Text(
        "Error loading history",
        style: TextStyle(color: AppColors.mistake),
      ),
    );
  }

  Widget _buildPrayerProgressCard(BuildContext context, WidgetRef ref, bool isDark) {
    final prayers = ref.watch(prayerProvider);
    final prayerNotifier = ref.read(prayerProvider.notifier);
    final overallProgress = prayerNotifier.getProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Spiritual Consistency",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${(overallProgress * 100).round()}%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                      Text(
                        "Daily Completion",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  _buildPrayerIndicator(prayers),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: prayers.map((p) => _buildMiniPrayerStatus(p, isDark)).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms).moveY(begin: 20, end: 0),
      ],
    );
  }

  Widget _buildPrayerIndicator(List<PrayerStatus> prayers) {
    final offeredCount = prayers.where((p) => p.isPrayed).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$offeredCount/5 Prayers",
        style: const TextStyle(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrayerMiniStatus(PrayerStatus prayer, bool isDark) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: prayer.isPrayed ? AppColors.goldPrimary : (isDark ? Colors.white10 : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          prayer.name.substring(0, 1),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPrayerStatus(PrayerStatus p, bool isDark) {
     return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: p.isPrayed ? AppColors.goldPrimary : (isDark ? Colors.white10 : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          p.name.substring(0, 1),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
