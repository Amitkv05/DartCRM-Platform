import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static const _storage = FlutterSecureStorage();

  static const _apiTokenKey = 'crm_v2_api_token';
  static const _accessTokenKey = 'crm_v2_access_token';
  static const _refreshTokenKey = 'crm_v2_refresh_token';
  static const _apiTokenExpiryKey = 'crm_v2_api_token_expiry';

  static Future<String?> get apiToken => _storage.read(key: _apiTokenKey);
  static Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  static Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  static Future<String?> get apiTokenExpiry => _storage.read(key: _apiTokenExpiryKey);

  static Future<void> saveApiToken(String token, {String? expiresAt}) async {
    await _storage.write(key: _apiTokenKey, value: token);
    if (expiresAt != null) {
      await _storage.write(key: _apiTokenExpiryKey, value: expiresAt);
    }
  }

  static Future<void> saveUserTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<void> clearUserTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> clearApiToken() async {
    await _storage.delete(key: _apiTokenKey);
    await _storage.delete(key: _apiTokenExpiryKey);
  }

  static Future<void> clearAll() async {
    await clearUserTokens();
    await clearApiToken();
  }
}
