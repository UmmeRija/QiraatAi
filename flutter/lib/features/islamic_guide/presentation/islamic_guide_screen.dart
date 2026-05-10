import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/surah_provider.dart';

// ── Providers ──────────────────────────────────────────────────────────────
final namazStepsProvider = FutureProvider.family<List<dynamic>, String>((ref, gender) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/namaz-steps', queryParameters: {'gender': gender});
  return response.data as List<dynamic>;
});

final duasProvider = FutureProvider.family<List<dynamic>, String>((ref, category) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/duas', queryParameters: {'category': category});
  return response.data as List<dynamic>;
});

final adhkarProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/after-namaz-adhkar');
  return response.data as List<dynamic>;
});

final jumaGuideProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/juma-guide');
  return response.data as List<dynamic>;
});

final specialSurahsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/islamic-guide/special-surahs');
  return response.data as List<dynamic>;
});



// ── Main Screen ────────────────────────────────────────────────────────────
class IslamicGuideScreen extends StatelessWidget {
  const IslamicGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: AppBar(
          title: Text(
            'اسلامی رہنما',
            style: AppTheme.arabicStyle(fontSize: 22, isDark: isDark, color: AppColors.goldPrimary),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.goldPrimary,
            labelColor: AppColors.goldPrimary,
            unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.mosque_rounded), text: 'نماز'),
              Tab(icon: Icon(Icons.pan_tool_rounded), text: 'قنوت'),
              Tab(icon: Icon(Icons.nights_stay_rounded), text: 'جنازہ'),
              Tab(icon: Icon(Icons.history_toggle_off_rounded), text: 'اذکار'),
              Tab(icon: Icon(Icons.event_note_rounded), text: 'جمعہ'),
              Tab(icon: Icon(Icons.auto_stories_rounded), text: 'سورتیں'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NamazTab(),
            _DuaTab(category: 'qunoot', title: 'دعائے قنوت'),
            _DuaTab(category: 'janaza', title: 'نمازِ جنازہ'),
            _AdhkarTab(),
            _JumaTab(),
            _SpecialSurahsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Namaz Tab ──────────────────────────────────────────────────────────────
class _NamazTab extends ConsumerStatefulWidget {
  const _NamazTab();
  @override
  ConsumerState<_NamazTab> createState() => _NamazTabState();
}

class _NamazTabState extends ConsumerState<_NamazTab> {
  String _gender = 'mard';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stepsAsync = ref.watch(namazStepsProvider(_gender));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mard', label: Text('مرد'), icon: Icon(Icons.man)),
              ButtonSegment(value: 'aurat', label: Text('عورت'), icon: Icon(Icons.woman)),
            ],
            selected: {_gender},
            onSelectionChanged: (v) => setState(() => _gender = v.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.goldPrimary.withOpacity(0.2);
                }
                return isDark ? AppColors.darkSurface : AppColors.lightSurface;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.goldPrimary;
                return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
              }),
            ),
          ),
        ),
        Expanded(
          child: stepsAsync.when(
            data: (steps) => ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              itemCount: steps.length,
              itemBuilder: (ctx, i) {
                final s = steps[i] as Map<String, dynamic>;
                return _NamazStepCard(
                  stepNumber: s['step_number'] ?? 0,
                  stepNameUrdu: s['step_name_urdu'] ?? '',
                  arabicText: s['arabic_text'],
                  urduTranslation: s['urdu_translation'],
                  urduTransliteration: s['urdu_transliteration'],
                  description: s['description'] ?? '',
                  hasDifference: s['has_difference'] == true,
                  differenceNote: s['difference_note'],
                ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideY(begin: 0.1, end: 0);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
            error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(namazStepsProvider(_gender)), error: e.toString()),
          ),
        ),
      ],
    );
  }
}

// ── Dua Tab (Generic for Qunoot/Janaza) ───────────────────────────────────
class _DuaTab extends ConsumerWidget {
  final String category;
  final String title;
  const _DuaTab({required this.category, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duasAsync = ref.watch(duasProvider(category));

    return duasAsync.when(
      data: (duas) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: duas.length,
        itemBuilder: (ctx, i) {
          final d = duas[i] as Map<String, dynamic>;
          return _GenericDuaCard(
            title: d['title_urdu'],
            arabicText: d['arabic_text'],
            urduTranslation: d['urdu_translation'],
            notes: d['notes'],
          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().scale();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(duasProvider(category)), error: e.toString()),
    );
  }
}

// ── Adhkar Tab ─────────────────────────────────────────────────────────────
class _AdhkarTab extends ConsumerWidget {
  const _AdhkarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adhkarAsync = ref.watch(adhkarProvider);

    return adhkarAsync.when(
      data: (adhkar) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adhkar.length,
        itemBuilder: (ctx, i) {
          final a = adhkar[i] as Map<String, dynamic>;
          return _AdhkarCard(
            title: a['title_urdu'],
            arabicText: a['arabic_text'],
            translation: a['urdu_translation'],
            repeatCount: a['repeat_count'],
            notes: a['notes'],
          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(adhkarProvider), error: e.toString()),
    );
  }
}

// ── Juma Tab ──────────────────────────────────────────────────────────────
class _JumaTab extends ConsumerWidget {
  const _JumaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(jumaGuideProvider);

    return guideAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i] as Map<String, dynamic>;
          return _JumaItemCard(
            title: item['title_urdu'],
            description: item['description_urdu'],
            category: item['category'],
          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideY();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(jumaGuideProvider), error: e.toString()),
    );
  }
}

// ── Special Surahs Tab ────────────────────────────────────────────────────
class _SpecialSurahsTab extends ConsumerWidget {
  const _SpecialSurahsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(specialSurahsProvider);

    return surahsAsync.when(
      data: (surahs) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: surahs.length,
        itemBuilder: (ctx, i) {
          final s = surahs[i] as Map<String, dynamic>;
          return _SpecialSurahCard(
            surahNumber: s['surah_number'],
            name: s['name_urdu'],
            nameEnglish: s['name_english'],
            recommended: s['recommended_time'],
            fazilat: s['fazilat_urdu'],
          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().scale();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(specialSurahsProvider), error: e.toString()),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String error;
  const _ErrorView({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.mistake, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _GenericDuaCard extends StatelessWidget {
  final String title;
  final String arabicText;
  final String urduTranslation;
  final String? notes;

  const _GenericDuaCard({required this.title, required this.arabicText, required this.urduTranslation, this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldPrimary), textDirection: TextDirection.rtl),
            const Divider(height: 24),
            Text(arabicText, style: AppTheme.arabicStyle(fontSize: 24, isDark: isDark), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
            const SizedBox(height: 12),
            Text(urduTranslation, style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
            if (notes != null) ...[
              const SizedBox(height: 8),
              Text(notes!, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontStyle: FontStyle.italic), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  final String title;
  final String arabicText;
  final String translation;
  final int repeatCount;
  final String? notes;

  const _AdhkarCard({required this.title, required this.arabicText, required this.translation, required this.repeatCount, this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (repeatCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.goldPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3))),
                    child: Text('$repeatCount x', style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                  ),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
              ],
            ),
            const SizedBox(height: 12),
            Text(arabicText, style: AppTheme.arabicStyle(fontSize: 24, isDark: isDark), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
            const SizedBox(height: 8),
            Text(translation, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }
}

class _JumaItemCard extends StatelessWidget {
  final String title;
  final String description;
  final String? category;

  const _JumaItemCard({required this.title, required this.description, this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldPrimary), textDirection: TextDirection.rtl),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              category == 'sunnah' ? Icons.wb_sunny_rounded : Icons.star_rounded,
              color: AppColors.goldPrimary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialSurahCard extends StatelessWidget {
  final int surahNumber;
  final String name;
  final String nameEnglish;
  final String? recommended;
  final String? fazilat;

  const _SpecialSurahCard({required this.surahNumber, required this.name, required this.nameEnglish, this.recommended, this.fazilat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => context.push('/islamic-guide/surah/$surahNumber'),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: AppTheme.arabicStyle(fontSize: 22, isDark: isDark), textAlign: TextAlign.center),
              Text(nameEnglish, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldPrimary)),
              const Divider(height: 16),
              if (recommended != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recommended!,
                    style: const TextStyle(fontSize: 10, color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              if (fazilat != null)
                Expanded(
                  child: Text(
                    fazilat!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'سورت نمبر $surahNumber',
                style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── NamazStepCard Widget (Re-using fixed version) ──────────────────────────
class _NamazStepCard extends StatefulWidget {
  final int stepNumber;
  final String stepNameUrdu;
  final String? arabicText;
  final String? urduTranslation;
  final String? urduTransliteration;
  final String description;
  final bool hasDifference;
  final String? differenceNote;

  const _NamazStepCard({
    required this.stepNumber,
    required this.stepNameUrdu,
    this.arabicText,
    this.urduTranslation,
    this.urduTransliteration,
    required this.description,
    required this.hasDifference,
    this.differenceNote,
  });

  @override
  State<_NamazStepCard> createState() => _NamazStepCardState();
}

class _NamazStepCardState extends State<_NamazStepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: AppColors.goldPrimary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text('${widget.stepNumber}', style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.stepNameUrdu,
                              style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                      if (widget.arabicText != null && widget.arabicText!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(widget.arabicText!, style: AppTheme.arabicStyle(fontSize: 22, isDark: isDark), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                      ],
                      if (widget.urduTranslation != null && widget.urduTranslation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(widget.urduTranslation!, style: const TextStyle(fontSize: 14, color: AppColors.goldPrimary), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                      ],
                      const SizedBox(height: 8),
                      Text(widget.description, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                      if (widget.hasDifference) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(0.4))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade800),
                                const SizedBox(width: 6),
                                Text('مرد/عورت فرق', style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.amber.shade800),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: _expanded ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(widget.differenceNote ?? '', style: const TextStyle(fontSize: 13), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                          ) : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
