import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dio/dio.dart';

import 'api_result.dart';

/// Repository used by the legacy customer/edit screens.
///
/// The original implementation created its own Dio client, embedded an
/// ASP.NET session cookie, and relied on a global bearer token. CRM Backend V2
/// uses [CrmApiClient] for the shared API token + JWT lifecycle. Old endpoint
/// names are translated through [LegacyApiAdapter] so existing screens can be
/// migrated incrementally without keeping the insecure networking code.
class ApiRepository {
  ApiRepository({String token = ''});

  final LegacyApiAdapter _legacy = LegacyApiAdapter.instance;
  final CrmApiClient _api = CrmApiClient.instance;

  Response<dynamic> _response(String endpoint, dynamic data, {int statusCode = 200}) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: endpoint),
      data: data,
      statusCode: statusCode,
    );
  }

  ApiResult _errorResult(String endpoint, Object error) {
    if (error is DioException) {
      return ApiResult(error: error, response: error.response);
    }
    final exception = DioException(
      requestOptions: RequestOptions(path: endpoint),
      error: error,
      message: CrmApiClient.messageFrom(error),
      type: DioExceptionType.unknown,
    );
    return ApiResult(error: exception);
  }

  Future<Response<dynamic>> getCityByPincode({
    required String? pinCode,
    required String? cityId,
    required String? executiveId,
    required String? cityAccess,
  }) async {
    final endpoint = '/CityPinCodeAPI';
    final data = await _legacy.get(
      endpoint,
      queryParameters: {
        'PinCode': pinCode,
        'CityId': cityId,
        'ExecutiveId': executiveId,
        'CityAccess': cityAccess,
      },
    );
    return _response(endpoint, data);
  }

  Future<ApiResult> getRequest(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final data = await _legacy.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return ApiResult(response: _response(endpoint, data));
    } catch (error) {
      return _errorResult(endpoint, error);
    }
  }

  Future<ApiResult> postRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      // Backend V2 no longer uses the old multipart `savefile` endpoint.
      // LegacyApiAdapter returns a compatibility response for document
      // metadata while actual visit documents are stored with the visit.
      final mapped = await _legacy.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResult(response: _response(endpoint, mapped, statusCode: 200));
    } catch (error) {
      return _errorResult(endpoint, error);
    }
  }

  Future<ApiResult> putRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await _api.put(
        _v2Path(endpoint),
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResult(response: response);
    } catch (error) {
      return _errorResult(endpoint, error);
    }
  }

  Future<ApiResult> deleteRequest(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _api.delete(
        _v2Path(endpoint),
        queryParameters: queryParameters,
      );
      return ApiResult(response: response);
    } catch (error) {
      return _errorResult(endpoint, error);
    }
  }

  Future<ApiResult> patchRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await _api.patch(
        _v2Path(endpoint),
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResult(response: response);
    } catch (error) {
      return _errorResult(endpoint, error);
    }
  }

  String _v2Path(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri != null && uri.hasScheme) {
      final path = uri.path;
      return path.startsWith('/api/') ? path.substring(4) : path;
    }
    if (endpoint.startsWith('/api/')) return endpoint.substring(4);
    return endpoint.startsWith('/') ? endpoint : '/$endpoint';
  }
}
