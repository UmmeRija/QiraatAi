import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/data/auth_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.schedulePrayerNotifications();

  // Load session from SQL backend storage
  final authService = AuthService();
  final session = await authService.loadSession();
  
  runApp(
    ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(session),
      ],
      child: const QuranCheckApp(),
    ),
  );
}

class QuranCheckApp extends ConsumerWidget {
  const QuranCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QuranAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
