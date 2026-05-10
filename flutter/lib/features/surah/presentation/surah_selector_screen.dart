import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/surah_provider.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Search bar: Dark fill (#1A1A1A), gold focus ring, and gold icons.
2. Surah list tiles: Dark surface (#161616), gold surah number badge.
3. Arabic name: Right-aligned with Amiri font.
4. List items animate in with staggered FadeIn (50ms offset).
5. Range picker bottom sheet updated to dark surface with gold accents.
*/

class SurahSelectorScreen extends ConsumerStatefulWidget {
  const SurahSelectorScreen({super.key});

  @override
  ConsumerState<SurahSelectorScreen> createState() =>
      _SurahSelectorScreenState();
}

class _SurahSelectorScreenState extends ConsumerState<SurahSelectorScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahsAsync = ref.watch(surahsProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final listPadding = EdgeInsets.fromLTRB(20, 10, 20, 5 + 60 + bottomInset);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          "Surah Index",
          style: TextStyle(
            color: AppColors.goldPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Search Surah...",
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.goldPrimary,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.goldPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final filteredSurahs = surahs.where((s) {
            final name = s['name_english']?.toString().toLowerCase() ?? '';
            final id = s['surah_no']?.toString() ?? '';
            return name.contains(_searchQuery.toLowerCase()) ||
                id == _searchQuery;
          }).toList();

          return ListView.separated(
            padding: listPadding,
            itemCount: filteredSurahs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final surah = filteredSurahs[index];
              return InkWell(
                    onTap: () => _showRangePicker(context, surah, isDark),
                    onLongPress: () =>
                        context.push('/surah/${surah['surah_no']}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.goldPrimary.withOpacity(0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              surah['surah_no'].toString(),
                              style: const TextStyle(
                                color: AppColors.goldPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surah['name_english'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _infoChip(
                                      context,
                                      isDark,
                                      "Verses: ${surah['total_verses']}",
                                    ),
                                    const SizedBox(width: 8),
                                    _infoChip(
                                      context,
                                      isDark,
                                      surah['revelation_type'] ?? 'Meccan',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            surah['name_arabic'] ?? '',
                            style: AppTheme.arabicStyle(
                              fontSize: 24,
                              isDark: isDark,
                            ).copyWith(color: AppColors.goldPrimary),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (index % 15 * 50).ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.mistake, size: 60),
              const SizedBox(height: 16),
              Text(
                "Failed to load Surahs",
                style: TextStyle(color: AppColors.goldPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(surahsProvider),
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

  void _showRangePicker(
    BuildContext context,
    Map<String, dynamic> surah,
    bool isDark,
  ) {
    int totalAyahs = surah['total_verses'] ?? 7;
    int startAyah = 1;
    int endAyah = totalAyahs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Practice ${surah['name_english']}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select Ayah Range (1 - $totalAyahs)",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _rangeInput(
                          context,
                          isDark,
                          "From Ayah",
                          startAyah,
                          (val) => setModalState(() => startAyah = val),
                          totalAyahs,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _rangeInput(
                          context,
                          isDark,
                          "To Ayah",
                          endAyah,
                          (val) => setModalState(() => endAyah = val),
                          totalAyahs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (startAyah > endAyah) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Start Ayah cannot be greater than end Ayah",
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      context.push(
                        '/recitation?surahId=${surah['surah_no']}&startAyah=$startAyah&endAyah=$endAyah',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: isDark ? AppColors.darkBg : Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Start Recitation",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rangeInput(
    BuildContext context,
    bool isDark,
    String label,
    int value,
    Function(int) onChanged,
    int max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
            items: List.generate(max, (index) => index + 1)
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _infoChip(BuildContext context, bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGoldTintBg : AppColors.lightGoldTintBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
