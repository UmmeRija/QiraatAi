import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Score Counter: Animated count-up effect from 0 to final score.
2. Layout: Premium dark surface (#161616) cards on #0D0D0D background.
3. Word Items: Semantic colors (Green/Red) with subtle glow and gold borders.
4. Stat Chips: Refined with semantic tints and gold-accented text.
5. Feedback: Updated dialogs to match the new gold-themed aesthetic.
*/

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? analysisResult;

  const ResultsScreen({super.key, this.analysisResult});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = analysisResult ?? {
      "accuracy": 0.0,
      "word_analysis": [],
      "pronunciation_score": null
    };

    final List wordAnalysis = result['word_analysis'] ?? [];
    final double accuracy = (result['accuracy'] as num?)?.toDouble() ?? 0.0;
    final double? pronScore = (result['pronunciation_score'] as num?)?.toDouble();

    int correct = 0, incorrect = 0, missing = 0;
    for (var w in wordAnalysis) {
      final s = (w as Map<String, dynamic>)['status'];
      if (s == 'match') correct++;
      else if (s == 'incorrect') incorrect++;
      else if (s == 'missing') missing++;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          "Session Results",
          style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildScoreCard(context, isDark, accuracy, pronScore),
            const SizedBox(height: 32),
            
            if (wordAnalysis.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip("Correct", correct, AppColors.correct),
                  _buildStatChip("Errors", incorrect, AppColors.mistake),
                  _buildStatChip("Skipped", missing, AppColors.warning),
                ],
              ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 40),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Word Analysis",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 16),

            if (wordAnalysis.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text("No recitation data recorded.", style: TextStyle(color: AppColors.darkTextHint)),
              )
            else
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: wordAnalysis.take(100).map((w) => _buildWordItem(
                    context,
                    w as Map<String, dynamic>,
                    isDark,
                  )).toList(),
                ),
              ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: isDark ? AppColors.darkBg : Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text("Continue Practice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(delay: 1200.ms).moveY(begin: 20, end: 0),
            
            // --- Restored Ayah-by-Ayah Analysis ---
            if (result['ayah_analysis'] != null) ...[
              const SizedBox(height: 40),
              const Divider(color: AppColors.goldPrimary, thickness: 0.2),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ayah Breakdown",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              ...(result['ayah_analysis'] as List).map((a) {
                final ayah = a as Map<String, dynamic>;
                final score = (ayah['text_accuracy'] as num).toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: AppColors.goldPrimary, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          "${ayah['ayah_no']}",
                          style: TextStyle(color: isDark ? AppColors.darkBg : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Ayah ${ayah['ayah_no']} Accuracy",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        "${score.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: score >= 90 ? AppColors.correct : (score >= 70 ? Colors.blue : AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, bool isDark, double accuracy, double? pronScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Final Accuracy",
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: accuracy),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Text(
                "${value.toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldPrimary,
                ),
              );
            },
          ),
          
          if (pronScore != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Fluency Score: ", style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                Text("${pronScore.toStringAsFixed(0)}%", style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          _buildSummaryLabel(accuracy),
        ],
      ),
    ).animate().fadeIn().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSummaryLabel(double accuracy) {
    String text = "Needs Practice";
    Color color = AppColors.mistake;
    IconData icon = Icons.info_outline;

    if (accuracy >= 90) {
      text = "Excellent!";
      color = AppColors.correct;
      icon = Icons.stars_rounded;
    } else if (accuracy >= 70) {
      text = "Good Progress";
      color = Colors.blue;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWordItem(BuildContext context, Map<String, dynamic> wordData, bool isDark) {
    final status = wordData['status'] as String? ?? 'missing';
    String word = status == 'missing' ? (wordData['correct_word'] ?? '') : (wordData['correct_word'] ?? wordData['user_word'] ?? '—');

    Color statusColor = AppColors.goldPrimary;
    if (status == 'match') statusColor = AppColors.correct;
    else if (status == 'incorrect') statusColor = AppColors.mistake;
    else if (status == 'missing') statusColor = AppColors.warning;

    return InkWell(
      onTap: () => _showFeedbackPopup(context, wordData, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Text(
          word,
          style: AppTheme.arabicStyle(fontSize: 24, isDark: isDark, color: statusColor).copyWith(
            decoration: status == 'missing' ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  void _showFeedbackPopup(BuildContext context, Map<String, dynamic> wordData, bool isDark) {
    final status = wordData['status'];
    final userWord = wordData['user_word'] as String?;
    final correctWord = wordData['correct_word'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Word Feedback", style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            if (status == 'incorrect') ...[
              const Text("You recited:"),
              Text(userWord ?? '—', style: AppTheme.arabicStyle(fontSize: 32, isDark: isDark, color: AppColors.mistake)),
              const SizedBox(height: 16),
              const Text("Correct Word:"),
              Text(correctWord ?? '—', style: AppTheme.arabicStyle(fontSize: 32, isDark: isDark, color: AppColors.correct)),
            ] else if (status == 'missing') ...[
              const Text("Omitted Word:"),
              Text(correctWord ?? '—', style: AppTheme.arabicStyle(fontSize: 32, isDark: isDark, color: AppColors.warning)),
              const SizedBox(height: 12),
              const Text("This word was skipped during recitation."),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Got it"),
            ),
          ],
        ),
      ),
    );
  }
}
