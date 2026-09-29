import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CrmApiClient {
  CrmApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    _plainDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final apiToken = await ensureApiToken();
            options.headers['x-api-token'] = apiToken;
            final accessToken = await TokenStorage.accessToken;
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            handler.next(options);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: e,
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode == 401 &&
              request.extra['crmRetried'] != true &&
              !request.path.endsWith('/token')) {
            request.extra['crmRetried'] = true;
            try {
              final message = _extractMessage(error.response?.data).toLowerCase();
              if (message.contains('api token')) {
                await TokenStorage.clearApiToken();
                request.headers['x-api-token'] = await ensureApiToken(force: true);
              } else {
                final refreshed = await refreshAccessToken();
                if (!refreshed) return handler.next(error);
                final access = await TokenStorage.accessToken;
                request.headers['Authorization'] = 'Bearer $access';
              }
              final response = await _dio.fetch(request);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final CrmApiClient instance = CrmApiClient._();
  late final Dio _dio;
  late final Dio _plainDio;
  Future<String>? _apiTokenFuture;
  Future<bool>? _refreshFuture;

  Future<String> ensureApiToken({bool force = false}) async {
    if (!force) {
      final existing = await TokenStorage.apiToken;
      final expiryRaw = await TokenStorage.apiTokenExpiry;
      final expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
      if (existing != null &&
          existing.isNotEmpty &&
          (expiry == null || expiry.isAfter(DateTime.now().add(const Duration(minutes: 2))))) {
        return existing;
      }
    }

    if (_apiTokenFuture != null) return _apiTokenFuture!;
    _apiTokenFuture = _createApiToken();
    try {
      return await _apiTokenFuture!;
    } finally {
      _apiTokenFuture = null;
    }
  }

  Future<String> _createApiToken() async {
    try {
      final response = await _plainDio.post(
        '/token',
        data: {
          'email': AppConfig.serviceEmail,
          'secret': AppConfig.serviceSecret,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['apiToken']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException('API token was not returned by the server');
      }
      await TokenStorage.saveApiToken(
        token,
        expiresAt: data['expiresAt']?.toString(),
      );
      return token;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e.response?.data), e.response?.statusCode);
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshFuture != null) return _refreshFuture!;
    _refreshFuture = _refreshAccessTokenInternal();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _refreshAccessTokenInternal() async {
    final refresh = await TokenStorage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final apiToken = await ensureApiToken();
      final response = await _plainDio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(headers: {'x-api-token': apiToken}),
      );
      final access = response.data['accessToken']?.toString();
      if (access == null || access.isEmpty) return false;
      await TokenStorage.saveAccessToken(access);
      return true;
    } catch (_) {
      await TokenStorage.clearUserTokens();
      return false;
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _guard(() => _dio.get(path, queryParameters: queryParameters, options: options));

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _guard(() => _dio.post(path, data: data, queryParameters: queryParameters, options: options));

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _guard(() => _dio.put(path, data: data, queryParameters: queryParameters, options: options));

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _guard(() => _dio.patch(path, data: data, queryParameters: queryParameters, options: options));

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _guard(() => _dio.delete(path, data: data, queryParameters: queryParameters, options: options));

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException(_friendlyDioMessage(error), error.response?.statusCode);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Unexpected CRM error. Please try again.');
    }
  }

  static String _friendlyDioMessage(DioException error) {
    final serverMessage = _extractMessage(error.response?.data);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The CRM server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to the CRM server. Check your internet/network and server URL.';
      case DioExceptionType.badCertificate:
        return 'The CRM server certificate is not trusted.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401) {
          return serverMessage == 'Request failed'
              ? 'Your session has expired. Please log in again.'
              : serverMessage;
        }
        if (error.response?.statusCode != null && error.response!.statusCode! >= 500) {
          return serverMessage == 'Request failed'
              ? 'The CRM server could not complete the request. Please try again.'
              : serverMessage;
        }
        return serverMessage;
      case DioExceptionType.unknown:
        return serverMessage == 'Request failed'
            ? 'Unable to complete the request. Please try again.'
            : serverMessage;
    }
  }

  static String messageFrom(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) return _friendlyDioMessage(error);
    return error.toString().replaceFirst('Exception: ', '');
  }

  static String _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['Message']?.toString() ??
          data['error']?.toString() ??
          'Request failed';
    }
    return data?.toString() ?? 'Request failed';
  }
}
