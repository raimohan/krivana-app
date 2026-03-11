import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'services/backend/backend_service.dart';
import 'services/notifications/local_notification_service.dart';

class KrivanaApp extends ConsumerStatefulWidget {
  const KrivanaApp({super.key});

  @override
  ConsumerState<KrivanaApp> createState() => _KrivanaAppState();
}

class _KrivanaAppState extends ConsumerState<KrivanaApp> {
  bool _startupScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startupScheduled) return;
      _startupScheduled = true;
      unawaited(_bootstrapServices());
    });
  }

  Future<void> _bootstrapServices() async {
    final settings = Hive.box(AppConstants.hiveSettingsBox);
    final backendUrl =
        settings.get(AppConstants.settingsBackendUrl) as String?;

    if (backendUrl != null && backendUrl.isNotEmpty) {
      BackendService.instance.configure(backendUrl);
      ref.read(backendUrlProvider.notifier).state = backendUrl;
    }

    try {
      await LocalNotificationService.instance.initialize();
      await LocalNotificationService.instance.requestPermissions();
      LocalNotificationService.instance.flushPendingNavigation();
    } catch (_) {
      // Notification setup should never block app startup.
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Krivana',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
