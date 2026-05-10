import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'surah_provider.dart';
import '../../features/auth/data/auth_service.dart';

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState == null) return {"total_sessions": 0, "average_accuracy": 0, "history": []};

  final apiService = ref.watch(apiServiceProvider);
  return apiService.getStats();
});

final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState == null) return [];

  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSessions(limit: 5);
});

