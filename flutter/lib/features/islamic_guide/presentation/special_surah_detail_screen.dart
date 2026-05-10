import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/surah_provider.dart';
import '../../surah/presentation/ayah_display_card.dart';

final specialSurahDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, surahNumber) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/special-surahs/$surahNumber');
  return response.data as Map<String, dynamic>;
});

class SpecialSurahDetailScreen extends ConsumerWidget {
  final int surahNumber;
  const SpecialSurahDetailScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailAsync = ref.watch(specialSurahDetailProvider(surahNumber));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: detailAsync.when(
        data: (data) {
          final info = data['surah_info'] as Map<String, dynamic>;
          final ayahs = data['ayahs'] as List<dynamic>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    info['name_urdu'],
                    style: AppTheme.arabicStyle(fontSize: 22, isDark: isDark, color: Colors.white),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.goldPrimary, AppColors.goldDark],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${info['total_ayahs']} آیات',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info['fazilat_urdu'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (surahNumber != 1 && surahNumber != 9)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
                        style: AppTheme.arabicStyle(fontSize: 28, isDark: isDark, color: AppColors.goldPrimary),
                      ),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = ayahs[index];
                    return AyahDisplayCard(
                      surahNumber: surahNumber,
                      ayahNumber: a['ayah_number'],
                      arabicText: a['arabic_text'],
                      urduTranslation: a['urdu_translation'],
                    );
                  },
                  childCount: ayahs.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e'),
              ElevatedButton(
                onPressed: () => ref.invalidate(specialSurahDetailProvider(surahNumber)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
