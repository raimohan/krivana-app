import '../../core/utils/logger.dart';

class GitHubService {
  GitHubService();
  static final instance = GitHubService();

  String? _accessToken;
  String? _username;
  String? _avatarUrl;

  bool get isConnected => _accessToken != null;
  String? get username => _username;
  String? get avatarUrl => _avatarUrl;

  /// Start OAuth flow — returns username on success, null on failure.
  Future<String?> startOAuth() async {
    // TODO: Implement real OAuth with flutter_appauth
    AppLogger.info('Starting GitHub OAuth...');
    return null;
  }

  void setCredentials({
    required String accessToken,
    String? username,
    String? avatarUrl,
  }) {
    _accessToken = accessToken;
    _username = username;
    _avatarUrl = avatarUrl;
    AppLogger.info('GitHub connected: $username');
  }

  void disconnect() {
    _accessToken = null;
    _username = null;
    _avatarUrl = null;
  }
}
