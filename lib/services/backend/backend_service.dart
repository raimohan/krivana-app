import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

class BackendService {
  BackendService({String? baseUrl}) {
    if (baseUrl != null) {
      configure(baseUrl);
    }
  }

  static final instance = BackendService();

  Dio? _dio;

  void configure(String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
    ));
  }

  Dio get dio {
    if (_dio == null) {
      throw const AppException('Backend not configured');
    }
    return _dio!;
  }

  Future<bool> healthCheck() async {
    try {
      final response = await dio.get(ApiEndpoints.health);
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Health check failed', e);
      return false;
    }
  }

  Future<bool> verifyConnection(String url) async {
    try {
      final testDio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 10),
      ));
      final response = await testDio.get(ApiEndpoints.health);
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Backend verification failed', e);
      return false;
    }
  }
}
