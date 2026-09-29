import 'package:dio/dio.dart';

class ApiResult<T> {
  final Response? response;
  final DioException? error;

  ApiResult({
    this.response,
    this.error,
  });

  bool get isSuccess =>
      response != null &&
          (response!.statusCode == 200 ||
              response!.statusCode == 201 ||
              response!.statusCode == 202 ||
              response!.statusCode == 203 ||
              response!.statusCode == 204);
}
