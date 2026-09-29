import 'dart:async';

import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'util/constants/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isTimerComplete = false;
  bool _isAuthInitialized = false;
  String? _targetRoute; // Store the target route until timer completes

  Timer? _timer; // Store the timer to cancel it later

  @override
  void initState() {
    super.initState();
    // Start a 3-second timer to ensure splash screen is shown for at least 2 seconds
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTimerComplete = true;
        });
        // Check if auth is initialized and navigate if ready
        if (_isAuthInitialized && !_hasNavigated) {
          _navigateToTargetRoute();
        }
      }
    });

    // Trigger auth initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadStoredCredentials();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent setState after dispose
    super.dispose();
  }

  void _navigateToTargetRoute() {
    if (_hasNavigated || _targetRoute == null) return;
    _hasNavigated = true;
    print('Navigating to: $_targetRoute');
    Navigator.of(context).pushReplacementNamed(_targetRoute!);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      print(
          'AuthState: isInitialized=${next.isInitialized}, isLoading=${next.isLoading}, loginResponse=${next.loginResponse != null}, token=${next.token != null}, error=${next.errorMessage}');

      if (_hasNavigated || !next.isInitialized) return;

      _isAuthInitialized = true;
      if (next.errorMessage != null && _retryCount < _maxRetries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _retryCount++;
                _hasNavigated = false; // Allow retry
                _isAuthInitialized = false;
                ref.read(authProvider.notifier).loadStoredCredentials();
              },
            ),
          ),
        );
        return;
      }

      // Determine the target route
      _targetRoute =
          next.loginResponse != null && next.token != null ? '/home' : '/login';

      // Only navigate if the timer has completed
      if (_isTimerComplete) {
        _navigateToTargetRoute();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 90,
                width: 250,
                child: Image.asset("assets/dartCRM_logo.jpeg"),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.052),
              Container(
                height: 40,
                width: 100,
                child: Image.asset("assets/Avant_logo.jpeg"),
              ),
              const SizedBox(height: 20),
              if (authState.isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
