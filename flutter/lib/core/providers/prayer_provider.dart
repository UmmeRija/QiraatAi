import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerStatus {
  final String name;
  final bool isPrayed;
  final bool hasReadAzkar;
  final Map<String, bool> readSurahs;
  final List<String> recommendedSurahs;

  PrayerStatus({
    required this.name,
    this.isPrayed = false,
    this.hasReadAzkar = false,
    this.readSurahs = const {},
    this.recommendedSurahs = const [],
  });

  PrayerStatus copyWith({
    bool? isPrayed,
    bool? hasReadAzkar,
    Map<String, bool>? readSurahs,
  }) {
    return PrayerStatus(
      name: name,
      isPrayed: isPrayed ?? this.isPrayed,
      hasReadAzkar: hasReadAzkar ?? this.hasReadAzkar,
      readSurahs: readSurahs ?? this.readSurahs,
      recommendedSurahs: recommendedSurahs,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'isPrayed': isPrayed,
        'hasReadAzkar': hasReadAzkar,
        'readSurahs': readSurahs,
      };

  factory PrayerStatus.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final recSurahs = _getRecommendedSurahs(name);
    final savedReadSurahs = Map<String, bool>.from(json['readSurahs'] ?? {});
    
    final Map<String, bool> fullReadSurahs = {};
    for (var s in recSurahs) {
      fullReadSurahs[s] = savedReadSurahs[s] ?? false;
    }

    return PrayerStatus(
      name: name,
      isPrayed: json['isPrayed'] ?? false,
      hasReadAzkar: json['hasReadAzkar'] ?? false,
      readSurahs: fullReadSurahs,
      recommendedSurahs: recSurahs,
    );
  }

  static List<String> _getRecommendedSurahs(String name) {
    switch (name) {
      case 'Fajr': return ['Yaseen', 'Fajr'];
      case 'Zuhr': return ['Fatah'];
      case 'Asr': return ['Naba'];
      case 'Maghrib': return ['Waqia', 'Muzamil'];
      case 'Isha': return ['Mulk'];
      default: return [];
    }
  }
}

class PrayerNotifier extends StateNotifier<List<PrayerStatus>> {
  PrayerNotifier() : super(_initialPrayers()) {
    _loadFromPrefs();
  }

  static List<PrayerStatus> _initialPrayers() {
    return [
      'Fajr', 'Zuhr', 'Asr', 'Maghrib', 'Isha'
    ].map((name) {
      final recs = PrayerStatus._getRecommendedSurahs(name);
      return PrayerStatus(
        name: name,
        recommendedSurahs: recs,
        readSurahs: {for (var s in recs) s: false},
      );
    }).toList();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('prayer_status_v2'); // New version for schema change
    final String? lastDate = prefs.getString('prayer_status_date');
    final String today = DateTime.now().toIso8601String().split('T')[0];

    if (data != null && lastDate == today) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((e) => PrayerStatus.fromJson(e)).toList();
    } else {
      state = _initialPrayers();
      await prefs.setString('prayer_status_date', today);
      _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('prayer_status_v2', encoded);
  }

  void togglePrayer(String name) {
    state = [
      for (final prayer in state)
        if (prayer.name == name)
          prayer.copyWith(isPrayed: !prayer.isPrayed)
        else
          prayer
    ];
    _saveToPrefs();
  }

  void toggleAzkar(String name) {
    state = [
      for (final prayer in state)
        if (prayer.name == name)
          prayer.copyWith(hasReadAzkar: !prayer.hasReadAzkar)
        else
          prayer
    ];
    _saveToPrefs();
  }

  void toggleSurah(String prayerName, String surahName) {
    state = [
      for (final prayer in state)
        if (prayer.name == prayerName)
          prayer.copyWith(
            readSurahs: {
              ...prayer.readSurahs,
              surahName: !(prayer.readSurahs[surahName] ?? false),
            },
          )
        else
          prayer
    ];
    _saveToPrefs();
  }

  double getProgress() {
    if (state.isEmpty) return 0.0;
    int totalSteps = 0;
    int completedSteps = 0;

    for (var prayer in state) {
      totalSteps++;
      if (prayer.isPrayed) completedSteps++;

      totalSteps++;
      if (prayer.hasReadAzkar) completedSteps++;

      for (var entry in prayer.readSurahs.entries) {
        totalSteps++;
        if (entry.value) completedSteps++;
      }
    }

    return completedSteps / totalSteps;
  }
}

final prayerProvider = StateNotifierProvider<PrayerNotifier, List<PrayerStatus>>((ref) {
  return PrayerNotifier();
});
