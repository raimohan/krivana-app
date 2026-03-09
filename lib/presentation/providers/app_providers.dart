import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod/legacy.dart';
import '../../core/constants/app_constants.dart';

enum ConnectionStatus { connected, disconnected, reconnecting }

final backendUrlProvider = StateProvider<String?>((ref) {
  final box = Hive.box(AppConstants.hiveSettingsBox);
  return box.get(AppConstants.settingsBackendUrl) as String?;
});

final connectionStatusProvider =
    StateProvider<ConnectionStatus>((ref) => ConnectionStatus.disconnected);

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final box = Hive.box(AppConstants.hiveSettingsBox);
  final mode = box.get(AppConstants.settingsThemeMode, defaultValue: 'dark');
  return switch (mode) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
});

final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final box = Hive.box(AppConstants.hiveSettingsBox);
  return box.get(AppConstants.settingsOnboardingComplete,
          defaultValue: false) as bool;
});

final gitHubConnectedProvider = StateProvider<bool>((ref) {
  final box = Hive.box(AppConstants.hiveSettingsBox);
  return box.get(AppConstants.settingsGitHubConnected, defaultValue: false)
      as bool;
});
