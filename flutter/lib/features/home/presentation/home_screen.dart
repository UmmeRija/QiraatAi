import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/stats_provider.dart';
import '../../../core/providers/prayer_provider.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Streak card: Gold gradient border with dark fill (#1A1A1A).
2. Accuracy chart: Gold line (#C9A84C) on dark grid.
3. Quick start button: Gold pill button with arrow icon.
4. Cards animate in with FadeIn + slight upward slide (moveY) on page load.
5. Applied full gold-based theme to all elements.
6. Weekly progress chart now has day labels, percentage labels, summary cards, and motivational messages.
*/

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
          "QiraatAI",
          style: AppTheme.arabicStyle(
            fontSize: 24,
            isDark: isDark,
          ).copyWith(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.goldPrimary,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : Colors.white,
                  child: Icon(
                    Icons.person,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                _buildStreakCard(context, isDark, stats['streak'] ?? 0),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Continue Practice",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                    ),
                    TextButton(
                      onPressed: () => context.push('/surahs'),
                      child: Text(
                        "View All",
                        style: TextStyle(color: AppColors.goldPrimary),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),
                _buildQuickStartCard(context, isDark, stats['last_session']),

                const SizedBox(height: 24),
                _buildPrayerTrackerSection(context, ref, isDark),

                const SizedBox(height: 20),
                _buildSummaryRow(context, ref, isDark, stats),

                const SizedBox(height: 24),
                Text(
                  "Weekly Progress",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),
                _buildProgressChart(
                  context,
                  isDark,
                  (stats['weekly_progress'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
                ),
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
                "Failed to load stats",
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

  Widget _buildStreakCard(BuildContext context, bool isDark, int streak) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.goldPrimary, AppColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5), // For border effect
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fireplace_rounded,
                    size: 40,
                    color: AppColors.goldPrimary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$streak Day Streak!",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streak > 0
                            ? "Consistency is the key, MashaAllah!"
                            : "Begin your journey today!",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .moveY(begin: 20, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildQuickStartCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic>? lastSession,
  ) {
    return InkWell(
      onTap: () {
        if (lastSession != null) {
          context.push('/recitation?surahId=${lastSession['surah_id']}');
        } else {
          context.push('/surahs');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                lastSession != null
                    ? Icons.play_arrow_rounded
                    : Icons.menu_book_rounded,
                color: isDark ? AppColors.darkBg : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastSession?['surah_name'] ?? "Select a Surah",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastSession != null
                        ? "Last practiced ${timeago.format(DateTime.parse(lastSession['timestamp']))}"
                        : "Start your daily recitation",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.goldPrimary,
              size: 18,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 800.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildSummaryRow(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Map<String, dynamic> stats,
  ) {
    final totalSessions = stats['total_sessions']?.toString() ?? '0';
    final averageAccuracyNum = stats['average_accuracy'] as num? ?? 0;
    final averageAccuracy = '${(averageAccuracyNum * 100).round()}%';
    
    final prayerProgress = ref.watch(prayerProvider.notifier).getProgress();
    final prayerPercentage = '${(prayerProgress * 100).round()}%';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniTile(context, isDark, 'Sessions', totalSessions),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniTile(context, isDark, 'Accuracy', averageAccuracy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniTile(context, isDark, 'Prayers', prayerPercentage),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniTile(
    BuildContext context,
    bool isDark,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.goldDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTrackerSection(BuildContext context, WidgetRef ref, bool isDark) {
    final prayers = ref.watch(prayerProvider);
    final prayerNotifier = ref.read(prayerProvider.notifier);
    final overallProgress = prayerNotifier.getProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              "Daily Prayer Tracker",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Georgia', // Serif look
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE0), // Creamy beige
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.goldPrimary.withOpacity(0.1)),
              ),
              child: Text(
                "${(overallProgress * 100).round()}% Done",
                style: const TextStyle(
                  color: Color(0xFFB8860B), // Darker gold for contrast
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: prayers.length,
            itemBuilder: (context, index) {
              final prayer = prayers[index];
              return _buildPrayerCard(context, ref, isDark, prayer, prayerNotifier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    PrayerStatus prayer,
    PrayerNotifier notifier,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: prayer.isPrayed 
            ? AppColors.goldPrimary.withOpacity(0.4) 
            : (isDark ? AppColors.darkBorder : Colors.grey[100]!),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
          children: [
            if (prayer.isPrayed)
              Container(height: 5, width: double.infinity, color: AppColors.goldPrimary),
            const SizedBox(height: 20),
            Text(
              prayer.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white10 : Colors.grey[100])!.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getPrayerEmoji(prayer.name),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                notifier.togglePrayer(prayer.name);
                if (!prayer.isPrayed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Masha'Allah! You offered ${prayer.name} prayer."),
                      backgroundColor: AppColors.goldPrimary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: prayer.isPrayed ? AppColors.goldPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: prayer.isPrayed ? AppColors.goldPrimary : (isDark ? AppColors.darkBorder : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Icon(
                  prayer.isPrayed ? Icons.check : null,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (prayer.isPrayed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  _buildSubTaskChip(
                    label: "Azkar",
                    icon: Icons.auto_awesome_rounded,
                    isActive: prayer.hasReadAzkar,
                    onTap: () => notifier.toggleAzkar(prayer.name),
                  ),
                  const SizedBox(height: 4),
                  ...prayer.recommendedSurahs.map((surah) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildSubTaskChip(
                        label: surah,
                        icon: Icons.menu_book_rounded,
                        isActive: prayer.readSurahs[surah] ?? false,
                        onTap: () => notifier.toggleSurah(prayer.name, surah),
                      ),
                    );
                  }),
                ],
              ),
            )
          else
            Text(
              "Not offered yet",
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
        ],
      ),
    ),
  ),
).animate().fadeIn(delay: 400.ms);
}

  IconData _getPrayerIcon(String name) {
    switch (name) {
      case 'Fajr': return Icons.wb_twilight_rounded;
      case 'Zuhr': return Icons.wb_sunny_rounded;
      case 'Asr': return Icons.wb_sunny_outlined;
      case 'Maghrib': return Icons.nightlight_round;
      case 'Isha': return Icons.bedtime_rounded;
      default: return Icons.access_time_rounded;
    }
  }

  Widget _buildSubTaskChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF5EFE0) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.goldPrimary.withOpacity(0.4) : AppColors.goldPrimary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFB8860B).withOpacity(isActive ? 1.0 : 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFFB8860B).withOpacity(isActive ? 1.0 : 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrayerEmoji(String name) {
    switch (name) {
      case 'Fajr': return '🌅';
      case 'Zuhr': return '☀️';
      case 'Asr': return '🌤️';
      case 'Maghrib': return '🌙';
      case 'Isha': return '🌑';
      default: return '🕌';
    }
  }

  Widget _buildSmallToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldPrimary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.goldPrimary : AppColors.darkBorder,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? AppColors.goldPrimary : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart(
    BuildContext context,
    bool isDark,
    List<double> weeklyProgress,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.only(
                top: 20,
                right: 20,
                left: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? AppColors.darkBorder.withOpacity(0.5)
                          : AppColors.lightBorder.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyProgress
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [AppColors.goldPrimary, AppColors.goldLight],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldPrimary.withOpacity(0.2),
                            AppColors.goldPrimary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Week summary + best day badge
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.goldPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getWeekSummary(weeklyProgress),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getWeekComparison(weeklyProgress),
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldPrimary, AppColors.goldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_getBestDay(weeklyProgress)}% best',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Motivational message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (AppColors.goldPrimary.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.goldPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_objects_outlined,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMotivationalMessage(weeklyProgress),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 1000.ms)
        .moveY(begin: 20, end: 0);
  }
}

// Helper functions for weekly stats
String _getWeekSummary(List<double> progress) {
  if (progress.isEmpty) return 'No data this week';

  final total = progress.reduce((a, b) => a + b);
  final avg = total / progress.length;

  if (avg >= 80) return 'Excellent week! 🌟';
  if (avg >= 60) return 'Good progress! 📈';
  if (avg >= 40) return 'Keep going! 💪';
  return 'Start strong today! ✨';
}

String _getWeekComparison(List<double> progress) {
  if (progress.isEmpty || progress.length < 2)
    return 'Complete 2+ sessions to see trend';

  final firstHalf =
      progress.take(progress.length ~/ 2).reduce((a, b) => a + b) /
      (progress.length ~/ 2);
  final secondHalf =
      progress.skip(progress.length ~/ 2).reduce((a, b) => a + b) /
      (progress.length ~/ 2);

  final diff = secondHalf - firstHalf;

  if (diff > 5) return '↑ ${diff.round()}% better than early week';
  if (diff < -5) return '↓ ${diff.abs().round()}% drop — time to refocus';
  return '→ Steady consistency MashaAllah';
}

int _getBestDay(List<double> progress) {
  if (progress.isEmpty) return 0;
  return progress.reduce((a, b) => a > b ? a : b).round();
}

String _getMotivationalMessage(List<double> progress) {
  final avg = progress.isEmpty
      ? 0
      : progress.reduce((a, b) => a + b) / progress.length;

  if (avg >= 90) {
    return "🏆 MashaAllah! Outstanding consistency! Keep this beautiful momentum with Quran.";
  } else if (avg >= 70) {
    return "📖 Beautiful effort! Even 15 minutes daily with Quran brings immense barakah.";
  } else if (avg >= 50) {
    return "💫 You're doing great! Remember: 'The best deeds are those done consistently, even if small.'";
  } else if (avg >= 30) {
    return "🌙 Don't give up! Start with just 1 ayah today — Allah loves the small consistent steps.";
  } else {
    return "🤲 Make today your day! Open the Quran, even for 5 minutes. Barakah awaits!";
  }
}
