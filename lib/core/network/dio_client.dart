import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  DioClient(this._secureStorage)
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
            receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.addAll([
      AuthInterceptor(dio, _secureStorage),
      _loggingInterceptor,
    ]);
  }

  Interceptor get _loggingInterceptor => InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('--> ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('<-- ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('X-- ${error.requestOptions.uri} :: ${error.message}');
          return handler.next(error);
        },
      );
}
