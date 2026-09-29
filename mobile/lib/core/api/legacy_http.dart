import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'legacy_api_adapter.dart';

/// Tiny compatibility layer that exposes the subset of `package:http` used by
/// the unfinished CRM screens. It routes the old endpoint names through
/// [LegacyApiAdapter], which in turn calls CRM Backend V2 with the shared API
/// token and JWT handled by [CrmApiClient].
///
/// This is intentionally temporary: newly written screens should use
/// CrmApiClient/providers directly.
class Response {
  final String body;
  final int statusCode;
  final String? reasonPhrase;

  const Response(
    this.body,
    this.statusCode, {
    this.reasonPhrase,
  });
}

Future<Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  try {
    final mapped = await LegacyApiAdapter.instance.post(
      url.toString(),
      data: _decodeBody(body),
    );
    return Response(jsonEncode(mapped), 200, reasonPhrase: 'OK');
  } catch (error) {
    return _errorResponse(error);
  }
}

Future<Response> get(
  Uri url, {
  Map<String, String>? headers,
}) async {
  try {
    final mapped = await LegacyApiAdapter.instance.get(
      url.toString(),
      queryParameters: url.queryParameters.isEmpty
          ? null
          : Map<String, dynamic>.from(url.queryParameters),
    );
    return Response(jsonEncode(mapped), 200, reasonPhrase: 'OK');
  } catch (error) {
    return _errorResponse(error);
  }
}

dynamic _decodeBody(Object? body) {
  if (body == null) return null;
  if (body is Map || body is List) return body;
  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return body;
    }
  }
  return body;
}

Response _errorResponse(Object error) {
  int statusCode = 500;
  if (error is ApiException && error.statusCode != null) {
    statusCode = error.statusCode!;
  } else if (error is DioException && error.response?.statusCode != null) {
    statusCode = error.response!.statusCode!;
  }
  final message = CrmApiClient.messageFrom(error);
  return Response(
    jsonEncode({
      'Status': 'Error',
      'Message': message,
      'error': message,
    }),
    statusCode,
    reasonPhrase: message,
  );
}
