import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/surah_provider.dart';
import 'surah_info_card.dart';
import 'ayah_display_card.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final surahInfoProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  surahNumber,
) async {
  final api = ref.read(apiServiceProvider);
  return api.getSurahInfo(surahNumber);
});

final kanzulImanProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  surahNumber,
) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getKanzulImanSurah(surahNumber);
  return data['ayahs'] as List<dynamic>;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class SurahDetailScreen extends ConsumerWidget {
  final int surahNumber;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final infoAsync = ref.watch(surahInfoProvider(surahNumber));
    final ayahsAsync = ref.watch(kanzulImanProvider(surahNumber));

    // Get surah name from info or use fallback
    final surahName = infoAsync.asData?.value['surah_name_urdu'] as String? ?? 'سورہ $surahNumber';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        elevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.goldPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              surahName,
              style: const TextStyle(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Surah $surahNumber',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.goldPrimary,
              size: 20,
            ),
            onPressed: () {
              ref.invalidate(surahInfoProvider(surahNumber));
              ref.invalidate(kanzulImanProvider(surahNumber));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Shaane Nuzool Card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: infoAsync.when(
                data: (info) => SurahInfoCard(surahInfo: info)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05, end: 0),
                loading: () => _buildInfoShimmer(isDark),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Section Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'کنزالایمان ترجمہ',
                    style: TextStyle(
                      color: AppColors.goldPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const Spacer(),
                  Text(
                    'Kanzul Iman Translation',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

          // ── Ayah List ──────────────────────────────────────────────────
          ayahsAsync.when(
            data: (ayahs) => SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= ayahs.length) return null;
                final ayah = ayahs[index] as Map<String, dynamic>;
                return AyahDisplayCard(
                  surahNumber: surahNumber,
                  ayahNumber: ayah['ayah_number'] as int? ?? (index + 1),
                  arabicText: ayah['arabic_text'] as String? ?? '',
                  urduTranslation: ayah['urdu_translation'] as String? ?? '',
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * (index % 10)),
                  duration: 300.ms,
                );
              }, childCount: ayahs.length),
            ),
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AyahDisplayCard(
                  surahNumber: surahNumber,
                  ayahNumber: index + 1,
                  arabicText: '',
                  urduTranslation: '',
                  isLoading: true,
                ),
                childCount: 5,
              ),
            ),
            error: (err, _) =>
                SliverToBoxAdapter(child: _buildError(context, ref, err)),
          ),

          // ── Bottom padding ─────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Shimmer for SurahInfoCard while loading ──────────────────────────────
  Widget _buildInfoShimmer(bool isDark) {
    return Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _shimmerBox(isDark, width: 60, height: 24, radius: 12),
                    const SizedBox(width: 8),
                    _shimmerBox(isDark, width: 100, height: 24, radius: 12),
                  ],
                ),
                const SizedBox(height: 12),
                _shimmerBox(isDark, width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _shimmerBox(isDark, width: 200, height: 14),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 1200.ms,
          color: AppColors.goldPrimary.withOpacity(0.08),
        );
  }

  Widget _shimmerBox(
    bool isDark, {
    double? width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.goldPrimary.withOpacity(0.4),
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Translation load nahi ho saki',
            style: TextStyle(
              color: AppColors.goldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            err.toString(),
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(kanzulImanProvider(surahNumber)),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Dobara Koshish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
