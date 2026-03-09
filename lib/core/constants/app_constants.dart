abstract class AppConstants {
  static const appName = 'Krivana';
  static const appVersion = '1.0.0';

  static const splashDuration = Duration(milliseconds: 2800);
  static const typingSpeed = Duration(milliseconds: 80);

  static const apiTimeout = Duration(seconds: 30);
  static const wsReconnectDelay = Duration(seconds: 2);
  static const maxRetries = 3;

  static const hiveProjectsBox = 'projects';
  static const hiveChatBox = 'chat_messages';
  static const hiveNotificationsBox = 'notifications';
  static const hiveSettingsBox = 'settings';

  static const settingsBackendUrl = 'backend_url';
  static const settingsThemeMode = 'theme_mode';
  static const settingsGitHubConnected = 'github_connected';
  static const settingsOnboardingComplete = 'onboarding_complete';
}
