import 'dart:convert';

import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/core/storage/token_storage.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/login_response.dart';
import 'package:dart_crm/models/menu.dart';
import 'package:dart_crm/models/setup_value.dart';
import 'package:dart_crm/providers/checkin_checkout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  /// User JWT access token. Existing screens/providers can continue reading
  /// state.token, but it now correctly means the per-user access token.
  final String? token;
  final String? refreshToken;
  final String? apiToken;
  final LoginResponse? loginResponse;
  final String? errorMessage;
  final String? successMessage;
  final List<Menu>? menus;
  final List<SetupValue>? setupValues;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.token,
    this.refreshToken,
    this.apiToken,
    this.loginResponse,
    this.errorMessage,
    this.successMessage,
    this.menus,
    this.setupValues,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? token,
    String? refreshToken,
    String? apiToken,
    LoginResponse? loginResponse,
    String? errorMessage,
    String? successMessage,
    List<Menu>? menus,
    List<SetupValue>? setupValues,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSession = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      token: clearSession ? null : (token ?? this.token),
      refreshToken: clearSession ? null : (refreshToken ?? this.refreshToken),
      apiToken: apiToken ?? this.apiToken,
      loginResponse: clearSession ? null : (loginResponse ?? this.loginResponse),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      menus: clearSession ? null : (menus ?? this.menus),
      setupValues: clearSession ? null : (setupValues ?? this.setupValues),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthState());

  final Ref ref;
  final CrmApiClient _api = CrmApiClient.instance;

  Future<void> loadStoredCredentials() async {
    state = state.copyWith(
      isLoading: true,
      isInitialized: false,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final loginJson = prefs.getString('crm_v2_login_response');
      final access = await TokenStorage.accessToken;
      final refresh = await TokenStorage.refreshToken;
      final apiToken = await TokenStorage.apiToken;

      if (loginJson == null || refresh == null) {
        state = const AuthState(isInitialized: true);
        return;
      }

      var usableAccess = access;
      if (usableAccess == null || usableAccess.isEmpty) {
        final refreshed = await _api.refreshAccessToken();
        if (!refreshed) {
          await _clearStoredCredentials();
          state = const AuthState(isInitialized: true);
          return;
        }
        usableAccess = await TokenStorage.accessToken;
      }

      final loginResponse = LoginResponse.fromJson(
        Map<String, dynamic>.from(jsonDecode(loginJson) as Map),
      );
      USER_LOGIN_DATA = loginResponse;
      await AppUtils.saveExecutive(loginResponse);

      state = AuthState(
        isInitialized: true,
        token: usableAccess,
        refreshToken: refresh,
        apiToken: apiToken,
        loginResponse: loginResponse,
      );

      await Future.wait([getMenus(), getSetupValues()]);
      await ref.read(checkinCheckoutProvider.notifier).loadStateForCurrentUser();
    } catch (e) {
      await _clearStoredCredentials();
      state = AuthState(
        isInitialized: true,
        errorMessage: 'Unable to restore session: ${CrmApiClient.messageFrom(e)}',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final apiToken = await _api.ensureApiToken();
      final response = await _api.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      raw['loginEmail'] = email.trim();

      final accessToken = raw['accessToken']?.toString();
      final refreshToken = raw['refreshToken']?.toString();
      if (accessToken == null || refreshToken == null) {
        throw ApiException('Login response did not contain access/refresh tokens');
      }

      await TokenStorage.saveUserTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      final loginResponse = LoginResponse.fromJson(raw);
      USER_LOGIN_DATA = loginResponse;
      await AppUtils.saveExecutive(loginResponse);
      await _saveLoginResponse(loginResponse);

      state = AuthState(
        isLoading: false,
        isInitialized: true,
        token: accessToken,
        refreshToken: refreshToken,
        apiToken: apiToken,
        loginResponse: loginResponse,
        successMessage: 'Login successful',
      );

      await Future.wait([getMenus(), getSetupValues()]);
      await ref.read(checkinCheckoutProvider.notifier).loadStateForCurrentUser();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: CrmApiClient.messageFrom(e),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final refresh = await TokenStorage.refreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } catch (_) {
      // Local logout must still succeed if the network is unavailable.
    } finally {
      await _clearStoredCredentials();
      ref.read(checkinCheckoutProvider.notifier).resetState();
      state = const AuthState(isInitialized: true, successMessage: 'Logged out');
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _api.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: response.data['message']?.toString() ?? 'Password reset request created',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: CrmApiClient.messageFrom(e),
      );
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.token == null) return 'Please login first';
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _api.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final message = response.data['message']?.toString() ?? 'Password changed successfully';
      state = state.copyWith(isLoading: false, successMessage: message);
      return message;
    } catch (e) {
      final message = CrmApiClient.messageFrom(e);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  Future<void> getMenus() async {
    if (state.token == null) return;
    try {
      final response = await _api.get('/menus');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = data['menus'] is List ? List<dynamic>.from(data['menus']) : <dynamic>[];
      final menus = rows
          .whereType<Map>()
          .map((e) => Menu.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(menus: menus);
    } catch (e) {
      state = state.copyWith(errorMessage: CrmApiClient.messageFrom(e));
    }
  }

  Future<void> getSetupValues() async {
    if (state.token == null) return;
    try {
      final response = await _api.get('/setup');
      final data = Map<String, dynamic>.from(response.data as Map);
      final setup = data['setup'] is Map
          ? Map<String, dynamic>.from(data['setup'] as Map)
          : <String, dynamic>{};
      var index = 1;
      final values = setup.entries
          .map((e) => SetupValue(
                id: index++,
                keyName: e.key,
                keyValue: e.value?.toString() ?? '',
                keyStatus: true,
                keyDescription: '',
              ))
          .toList();
      await AppUtils.saveSetUp(values);
      state = state.copyWith(setupValues: values);
    } catch (e) {
      state = state.copyWith(errorMessage: CrmApiClient.messageFrom(e));
    }
  }

  String? getSetupValue(String keyName) {
    for (final setup in state.setupValues ?? const <SetupValue>[]) {
      if (setup.keyName == keyName) return setup.keyValue;
    }
    return null;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> _saveLoginResponse(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_v2_login_response', jsonEncode(response.toJson()));
    final email = response.executiveBasicData?.firstOrNull?.userName;
    if (email != null) await prefs.setString('user_email', email);
  }

  Future<void> _clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await TokenStorage.clearUserTokens();
    await prefs.remove('crm_v2_login_response');
    await prefs.remove('user_login_data');
    await prefs.remove('executive_data');
    await prefs.remove('user_email');
    USER_LOGIN_DATA = null;
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
