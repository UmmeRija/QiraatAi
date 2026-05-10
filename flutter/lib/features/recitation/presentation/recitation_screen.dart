import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/providers/surah_provider.dart';

// Theme updated — logic unchanged
/*
Visual changes:
1. Arabic Text: Large (32px), Amiri font, RTL, off-white (#EEECE4).
2. Word Widgets: Individual containers with glow effects for correct (green) and mistake (red) words.
3. Word Animation: ScaleTransition (0.8 -> 1.0) when status changes from normal.
4. Record Button: 70px gold circle with a pulsing red ring animation while recording.
5. Waveform: Animated scaling bars (12 bars) that react during recording.
6. Hifz Mode & UI: Premium dark surface components with gold accents.
*/

class RecitationScreen extends ConsumerStatefulWidget {
  final int surahId;
  final int? startAyah;
  final int? endAyah;

  const RecitationScreen({
    super.key,
    required this.surahId,
    this.startAyah,
    this.endAyah,
  });

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> with SingleTickerProviderStateMixin {
  final RecordingService _recordingService = RecordingService();
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _hifzMode = false;
  bool _showHint = false;

  Map<String, dynamic>? _surahData;
  bool _isLoadingData = true;
  List<Map<String, dynamic>> _wordFeedback = [];
  Timer? _syncTimer;

  int _resolvedStartAyah = 1;
  int _resolvedEndAyah = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _resolvedStartAyah = widget.startAyah ?? 1;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadSurahData();
  }

  Future<void> _loadSurahData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.getSurahWords(widget.surahId);

      final List<Map<String, dynamic>> wordsList = [];
      final ayahs = data['ayahs'] as Map<String, dynamic>;

      int lastAyahInSurah = _resolvedStartAyah;
      for (final key in ayahs.keys) {
        final n = int.tryParse(key);
        if (n != null && n > lastAyahInSurah) lastAyahInSurah = n;
      }

      final int resolvedEnd = (widget.endAyah != null && widget.endAyah! > 0)
          ? widget.endAyah!
          : lastAyahInSurah;

      final int resolvedStart = _resolvedStartAyah;

      if (resolvedStart == 1 && ayahs.containsKey('0')) {
        for (var w in (ayahs['0'] as List)) {
          wordsList.add({'word': w['word'], 'status': 'normal', 'ayah': 0});
        }
      }

      for (int i = resolvedStart; i <= resolvedEnd; i++) {
        final key = i.toString();
        if (ayahs.containsKey(key)) {
          for (var w in (ayahs[key] as List)) {
            wordsList.add({'word': w['word'], 'status': 'normal', 'ayah': i});
          }
        }
      }

      setState(() {
        _surahData = data;
        _wordFeedback = wordsList;
        _isLoadingData = false;
        _resolvedStartAyah = resolvedStart;
        _resolvedEndAyah = resolvedEnd;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load Surah: $e")));
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        _pulseController.stop();
        final path = await _recordingService.stopRecording();
        setState(() => _isRecording = false);
        if (path != null) {
          await _analyzeRecitation(path);
        }
      } else {
        await _recordingService.startRecording();
        _pulseController.repeat(reverse: true);
        setState(() {
          _isRecording = true;
          for (var w in _wordFeedback) {
            w['status'] = 'normal';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _analyzeRecitation(String path) async {
    if (_resolvedEndAyah == 0) return;
    setState(() => _isAnalyzing = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.analyzeRecitation(
        surahId: widget.surahId,
        startAyah: _resolvedStartAyah,
        endAyah: _resolvedEndAyah,
        audioPath: path,
        saveSession: true,
      );

      final List analysis = result['word_analysis'] ?? [];
      _updateWordFeedback(analysis);

      if (mounted) {
        context.push('/results', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analysis error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _updateWordFeedback(List analysis) {
    setState(() {
      for (int i = 0; i < _wordFeedback.length; i++) {
        if (i < analysis.length) {
          _wordFeedback[i]['status'] = analysis[i]['status'] ?? 'missing';
        } else {
          _wordFeedback[i]['status'] = 'missing';
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          _isLoadingData ? "Loading..." : (_surahData?['name_english'] ?? "Recitation"),
          style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Text("Hifz Mode", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _hifzMode,
                  activeColor: AppColors.goldPrimary,
                  onChanged: (val) {
                    setState(() {
                      _hifzMode = val;
                      _showHint = false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Stack(
                      children: [
                        AnimatedOpacity(
                          duration: 400.ms,
                          opacity: (_hifzMode && !_showHint) ? 0.0 : 1.0,
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.center,
                                  children: _wordFeedback
                                      .map((w) => _buildWordWidget(w, isDark))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_hifzMode && !_showHint)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off_outlined, size: 80, color: AppColors.goldPrimary.withOpacity(0.2)),
                                const SizedBox(height: 24),
                                Text(
                                  "Recite from memory",
                                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 18),
                                ),
                                const SizedBox(height: 40),
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _showHint = true),
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: const Text("Show Hint"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.goldPrimary,
                                    side: const BorderSide(color: AppColors.goldPrimary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(),
                          ),
                      ],
                    ),
                  ),
                ),
                _buildControlSection(isDark),
              ],
            ),
    );
  }

  Widget _buildWordWidget(Map<String, dynamic> w, bool isDark) {
    final status = w['status'] as String;
    Color textColor = isDark ? AppColors.darkArabicText : AppColors.lightArabicText;
    Color glowColor = Colors.transparent;
    
    if (status == 'match') {
      textColor = Colors.white;
      glowColor = AppColors.correct;
    } else if (status == 'incorrect') {
      textColor = Colors.white;
      glowColor = AppColors.mistake;
    } else if (status == 'missing') {
      textColor = AppColors.warning;
    }

    return AnimatedContainer(
      duration: 300.ms,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: glowColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: status != 'normal' && status != 'missing' ? [
          BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
        ] : [],
      ),
      child: Text(
        w['word'],
        style: AppTheme.arabicStyle(fontSize: 32, isDark: isDark, color: textColor),
      ),
    ).animate(target: status == 'normal' ? 0 : 1)
     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildControlSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        children: [
          if (_isAnalyzing)
            Column(
              children: [
                const CircularProgressIndicator(color: AppColors.goldPrimary),
                const SizedBox(height: 20),
                Text("Analyzing Recitation...", style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
              ],
            ).animate().fadeIn()
          else if (_isRecording)
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(12, (index) {
                  return Container(
                    width: 4,
                    height: 15 + (index % 4) * 10.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleY(begin: 0.4, end: 1.6, duration: Duration(milliseconds: 200 + index * 40));
                }),
              ),
            )
          else
            Text(
              "Ready to Recite",
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          const SizedBox(height: 40),
          
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isRecording)
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.4).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mistake.withOpacity(0.5), width: 2),
                    ),
                  ),
                ),
              
              GestureDetector(
                onTap: _isAnalyzing ? null : _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? AppColors.mistake : AppColors.goldPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? AppColors.mistake : AppColors.goldPrimary).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 44,
                    color: isDark ? AppColors.darkBg : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
