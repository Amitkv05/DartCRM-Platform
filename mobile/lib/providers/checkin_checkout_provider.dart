import 'dart:async';

import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckinCheckoutState {
  final bool isCheckedIn;
  final bool isLoading;
  final String? message;
  final List<Map<String, String>> locationHistory;
  final String? event;
  final bool hasShownCheckinSnackbar;

  const CheckinCheckoutState({
    this.isCheckedIn = false,
    this.isLoading = false,
    this.message,
    this.locationHistory = const [],
    this.event,
    this.hasShownCheckinSnackbar = false,
  });

  CheckinCheckoutState copyWith({
    bool? isCheckedIn,
    bool? isLoading,
    String? message,
    List<Map<String, String>>? locationHistory,
    String? event,
    bool? hasShownCheckinSnackbar,
    bool clearMessage = false,
    bool clearEvent = false,
  }) {
    return CheckinCheckoutState(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      locationHistory: locationHistory ?? this.locationHistory,
      event: clearEvent ? null : (event ?? this.event),
      hasShownCheckinSnackbar:
          hasShownCheckinSnackbar ?? this.hasShownCheckinSnackbar,
    );
  }
}

class CheckinCheckoutNotifier extends StateNotifier<CheckinCheckoutState>
    with WidgetsBindingObserver {
  CheckinCheckoutNotifier(this.ref) : super(const CheckinCheckoutState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref ref;
  final CrmApiClient _api = CrmApiClient.instance;
  Timer? _locationTimer;
  bool _isCheckingOut = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      loadStateForCurrentUser();
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      state = state.copyWith(
        message: 'Please enable location services',
        event: 'error',
      );
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        message: 'Location permission is required for Check-In/Check-Out',
        event: 'error',
      );
      return false;
    }
    return true;
  }

  Future<Position> _position() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  Future<void> loadStateForCurrentUser() async {
    final auth = ref.read(authProvider);
    final executiveId = auth.loginResponse?.executiveBasicData?.firstOrNull?.executiveId;
    if (auth.token == null || executiveId == null) {
      state = const CheckinCheckoutState();
      return;
    }

    try {
      final response = await _api.get('/attendance/today');
      final data = Map<String, dynamic>.from(response.data as Map);
      final attendance = data['attendance'];
      final isCheckedIn = attendance is Map &&
          attendance['check_in_at'] != null &&
          attendance['check_out_at'] == null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_checked_in_$executiveId', isCheckedIn);
      state = state.copyWith(
        isCheckedIn: isCheckedIn,
        isLoading: false,
        clearMessage: true,
        clearEvent: true,
      );
      if (isCheckedIn) {
        _startLocationTracking();
      } else {
        _stopLocationTracking();
      }
    } catch (e) {
      // Keep the last local state if the server is temporarily unavailable.
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        isCheckedIn: prefs.getBool('is_checked_in_$executiveId') ?? false,
        isLoading: false,
      );
    }
  }

  void resetState() {
    _stopLocationTracking();
    state = const CheckinCheckoutState();
  }

  Future<void> checkIn() async {
    if (state.isLoading || state.isCheckedIn) return;
    final auth = ref.read(authProvider);
    final executiveId = auth.loginResponse?.executiveBasicData?.firstOrNull?.executiveId;
    if (auth.token == null || executiveId == null) {
      state = state.copyWith(message: 'Please login first', event: 'error');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearMessage: true,
      clearEvent: true,
      hasShownCheckinSnackbar: false,
    );
    try {
      if (!await _ensureLocationPermission()) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final pos = await _position();
      final response = await _api.post(
        '/attendance/check-in',
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_checked_in_$executiveId', true);
      state = state.copyWith(
        isCheckedIn: true,
        isLoading: false,
        message: data['message']?.toString() ?? 'Checked In successfully',
        event: 'checkin_success',
        hasShownCheckinSnackbar: true,
      );
      _startLocationTracking();
      await _captureAndSendLocation();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: CrmApiClient.messageFrom(e),
        event: 'error',
      );
    }
  }

  Future<void> checkOut() async {
    if (state.isLoading || _isCheckingOut || !state.isCheckedIn) return;
    _isCheckingOut = true;
    final executiveId = ref
        .read(authProvider)
        .loginResponse
        ?.executiveBasicData
        ?.firstOrNull
        ?.executiveId;
    state = state.copyWith(isLoading: true, clearMessage: true, clearEvent: true);
    try {
      if (!await _ensureLocationPermission()) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final pos = await _position();
      await _captureAndSendLocation(position: pos);
      final response = await _api.post(
        '/attendance/check-out',
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (executiveId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in_$executiveId', false);
      }
      _stopLocationTracking();
      state = state.copyWith(
        isCheckedIn: false,
        isLoading: false,
        message: data['message']?.toString() ?? 'Checked Out successfully',
        event: 'checkout_success',
        locationHistory: const [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: CrmApiClient.messageFrom(e),
        event: 'error',
      );
    } finally {
      _isCheckingOut = false;
    }
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _captureAndSendLocation(),
    );
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _captureAndSendLocation({Position? position}) async {
    if (!state.isCheckedIn) return;
    try {
      if (!await _ensureLocationPermission()) return;
      final pos = position ?? await _position();
      final timestamp = DateTime.now().toIso8601String();
      final entry = {
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'timestamp': timestamp,
      };
      final history = [...state.locationHistory, entry];
      state = state.copyWith(locationHistory: history);
      await _api.post(
        '/attendance/locations',
        data: {
          'locations': [
            {
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'recordedAt': timestamp,
            }
          ]
        },
      );
    } catch (_) {
      // Location tracking should not interrupt normal app use. The next timer
      // tick will retry with a fresh location.
    }
  }

  void clearMessageAndEvent() {
    state = state.copyWith(clearMessage: true, clearEvent: true);
  }

  Future<void> forceCheckDateChange() => loadStateForCurrentUser();
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final checkinCheckoutProvider =
    StateNotifierProvider<CheckinCheckoutNotifier, CheckinCheckoutState>((ref) {
  return CheckinCheckoutNotifier(ref);
});
