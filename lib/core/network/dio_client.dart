import 'package:dio/dio.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/network/network_info.dart';
import 'package:petconnect_ai/core/utils/logger.dart';

/// Configured [Dio] client for HTTP requests.
///
/// Wraps `dio` with interceptors for logging, error normalization, and
/// network pre-checks. All non-Supabase HTTP traffic should go through this
/// instance (Supabase SDK has its own built-in client).
///
/// Access via Riverpod (`dioClientProvider`).
class DioClient {
  DioClient({required this._logger, required this._networkInfo}) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _LoggingInterceptor(_logger),
      _ErrorInterceptor(),
    ]);
  }

  final AppLogger _logger;
  final NetworkInfo _networkInfo;
  late final Dio _dio;

  Dio get instance => _dio;

  /// Performs a GET request with network pre-check.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a POST request with network pre-check.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a PUT request with network pre-check.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a DELETE request with network pre-check.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) throw const NetworkException();
  }
}

class _LoggingInterceptor extends Interceptor {
  _LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('→ ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug('← ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}',
      err,
    );
    super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const RequestTimeoutException(),
      DioExceptionType.connectionError => const NetworkException(),
      DioExceptionType.badResponse => _mapStatusCode(err),
      DioExceptionType.cancel => const UnknownException('Request cancelled'),
      _ => UnknownException(err.message ?? 'Unknown error', err),
    };
  }

  AppException _mapStatusCode(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final message = _extractMessage(err.response);

    return switch (statusCode) {
      400 => ValidationException(message),
      401 => AuthException(message, statusCode: statusCode),
      403 => PermissionException(message, statusCode: statusCode),
      404 => NotFoundException(message),
      >= 500 => ServerException(message, statusCode: statusCode),
      _ => ServerException(message, statusCode: statusCode),
    };
  }

  String _extractMessage(Response<dynamic>? response) {
    if (response?.data is Map) {
      final data = response!.data as Map<String, dynamic>;
      return data['message'] as String? ??
          data['error'] as String? ??
          'Request failed';
    }
    return 'Request failed';
  }
}
