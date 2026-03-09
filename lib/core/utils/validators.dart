abstract class Validators {
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static bool isNotEmpty(String value) => value.trim().isNotEmpty;

  static String? validateApiKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API key cannot be empty';
    }
    if (value.trim().length < 8) {
      return 'API key seems too short';
    }
    return null;
  }
}
