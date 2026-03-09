import '../../core/utils/logger.dart';
import '../storage/secure_storage_service.dart';

class AiService {
  AiService();
  static final instance = AiService();

  String? _activeProvider;
  String? _activeModel;

  String? get activeProvider => _activeProvider;
  String? get activeModel => _activeModel;

  Future<void> loadConfig() async {
    final storage = SecureStorageService.instance;
    _activeProvider = await storage.read('ai_provider');
    _activeModel = await storage.read('ai_model');
  }

  Future<void> setProvider(String provider, String model) async {
    _activeProvider = provider;
    _activeModel = model;
    final storage = SecureStorageService.instance;
    await storage.write('ai_provider', provider);
    await storage.write('ai_model', model);
  }

  Future<void> saveApiKey(String provider, String key) async {
    await SecureStorageService.instance.write('api_key_$provider', key);
    AppLogger.info('API key saved for $provider');
  }

  Future<String?> getApiKey(String provider) async {
    return SecureStorageService.instance.read('api_key_$provider');
  }

  Future<void> saveModel(String provider, String model) async {
    await SecureStorageService.instance
        .write('ai_model_$provider', model);
    AppLogger.info('Model saved for $provider: $model');
  }
}
