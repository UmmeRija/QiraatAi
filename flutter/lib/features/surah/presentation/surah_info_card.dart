import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class SurahInfoCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> surahInfo;

  const SurahInfoCard({super.key, required this.surahInfo});

  @override
  ConsumerState<SurahInfoCard> createState() => _SurahInfoCardState();
}

class _SurahInfoCardState extends ConsumerState<SurahInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = widget.surahInfo['revelation_place'] as String? ?? 'Makki';
    final revelationOrder = widget.surahInfo['revelation_order'] as int? ?? 0;
    final ayatCount = widget.surahInfo['total_verses'] as int? ?? 0;
    final shaaneNuzool =
        widget.surahInfo['shaane_nuzool_urdu'] as String? ?? '';
    final keyThemes = (widget.surahInfo['key_themes'] as List<dynamic>?) ?? [];
    final keyEvents = (widget.surahInfo['key_events'] as List<dynamic>?) ?? [];
    // Always render the original text; collapsed view only limits lines.
    final description = shaaneNuzool;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightGoldTintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPill(
                isDark,
                type == 'Makki' ? 'مکی' : 'مدنی',
                AppColors.goldPrimary,
              ),
              const SizedBox(width: 8),
              _buildPill(
                isDark,
                'ترتیبِ نزول: $revelationOrder',
                AppColors.goldDark,
              ),
              const SizedBox(width: 8),
              _buildPill(isDark, '$ayatCount آیت', AppColors.goldLight),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'شانِ نزول',
            style: TextStyle(
              color: AppColors.goldPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (_isExpanded && keyEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'اہم واقعات',
              style: TextStyle(
                color: AppColors.goldPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: keyEvents
                  .map(
                    (event) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.goldDark)
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.goldPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        event.toString(),
                        style: TextStyle(
                          color: AppColors.goldPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_isExpanded && keyThemes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'مضمون اصلی',
              style: TextStyle(
                color: AppColors.goldPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: keyThemes
                  .map(
                    (theme) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.goldDark)
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.goldPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        theme.toString(),
                        style: TextStyle(
                          color: AppColors.goldPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded ? 'چھوٹا کریں' : 'مکمل پڑھیں',
                    style: TextStyle(
                      color: AppColors.goldPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(bool isDark, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
