import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl =>
      dotenv.env['CRM_API_BASE_URL'] ??
      'http://10.0.2.2:5000/api';

  static String get serviceEmail =>
      dotenv.env['CRM_SERVICE_EMAIL'] ?? '';

  static String get serviceSecret =>
      dotenv.env['CRM_SERVICE_SECRET'] ?? '';

  static String get serverBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';

    return '${uri.scheme}://${uri.host}$port';
  }
}