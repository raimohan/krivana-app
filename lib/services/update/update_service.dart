import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/logger.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.releaseNotes,
  });

  final String version;
  final String downloadUrl;
  final String? releaseNotes;
}

class UpdateService {
  static const _githubReleasesUrl =
      'https://api.github.com/repos/raimohan/krivana-app/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final current = await PackageInfo.fromPlatform();
      final response = await Dio().get(_githubReleasesUrl);
      final data = response.data as Map<String, dynamic>;
      final latestTag = data['tag_name'] as String;
      final latestVersion = latestTag.replaceFirst('v', '');
      if (_isNewer(latestVersion, current.version)) {
        final assets = data['assets'] as List<dynamic>?;
        return UpdateInfo(
          version: latestVersion,
          downloadUrl: assets != null && assets.isNotEmpty
              ? (assets[0] as Map<String, dynamic>)['browser_download_url']
                  as String
              : '',
          releaseNotes: data['body'] as String?,
        );
      }
    } catch (e) {
      AppLogger.error('Update check failed', e);
    }
    return null;
  }

  static bool _isNewer(String remote, String local) {
    final rParts = remote.split('.').map(int.tryParse).toList();
    final lParts = local.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final r = (i < rParts.length ? rParts[i] : 0) ?? 0;
      final l = (i < lParts.length ? lParts[i] : 0) ?? 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }
}
