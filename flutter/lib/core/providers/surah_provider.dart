import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../../features/auth/data/auth_service.dart';

// Service provider
final apiServiceProvider = Provider((ref) {
  // Watch authStateProvider so this provider rebuilds when user logs in/out
  ref.watch(authStateProvider);
  final authService = ref.read(authServiceProvider);
  return ApiService(authService.dio);
});

// Future provider for Surahs
final surahsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSurahs();
});

// Selected Surah ID Notifier
class SelectedSurahIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final selectedSurahIdProvider = NotifierProvider<SelectedSurahIdNotifier, int?>(() {
  return SelectedSurahIdNotifier();
});

// Selected Ayah range Notifier
class SelectedAyahRangeNotifier extends Notifier<Map<String, int?>> {
  @override
  Map<String, int?> build() => {
    'start': null,
    'end': null,
  };

  void setRange(int? start, int? end) {
    state = {'start': start, 'end': end};
  }
}

final selectedAyahRangeProvider = NotifierProvider<SelectedAyahRangeNotifier, Map<String, int?>>(() {
  return SelectedAyahRangeNotifier();
});
