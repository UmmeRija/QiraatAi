import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider((ref) {
  final service = AuthService(ref);
  return service;
});

// This provides the initial session from storage
final initialSessionProvider = Provider<Map<String, dynamic>?>((ref) => null);

// This notifier manages the current user session
class AuthNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    return ref.watch(initialSessionProvider);
  }

  void setSession(Map<String, dynamic>? session) {
    state = session;
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, Map<String, dynamic>?>(
  AuthNotifier.new,
);

class AuthService {
  final Ref? _ref;
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8000'
          : 'http://127.0.0.1:8000';
    } catch (_) {
      return 'http://127.0.0.1:8000';
    }
  }

  AuthService([this._ref]) {
    _dio.options.baseUrl = apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(minutes: 2);

    // Add an interceptor to automatically add the Bearer token to every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_ref != null) {
            final session = _ref.read(authStateProvider);
            if (session != null && session['token'] != null) {
              options.headers['Authorization'] = 'Bearer ${session['token']}';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }

  String get authBaseUrl => "$apiBaseUrl/api/v1/auth";

  // Getter for the shared Dio instance so other services can use it
  Dio get dio => _dio;

  // Sign Up
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "$authBaseUrl/signup",
        data: {"full_name": fullName, "email": email, "password": password},
      );

      await _saveSession(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "$authBaseUrl/login",
        data: {"email": email, "password": password},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Verify OTP and save session
  Future<Map<String, dynamic>> verifyOtp({
    required String tempToken,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        "$authBaseUrl/verify-otp",
        data: {"temp_token": tempToken, "otp_code": otpCode},
      );

      final data = Map<String, dynamic>.from(response.data);
      await _saveSession(data);
      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Save Session to Local Storage
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['access_token'];
    final user = data['user'];
    if (token == null || user == null) {
      throw Exception('Invalid session payload');
    }

    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: 'auth_token', value: token as String);
    await prefs.setString('user_data', jsonEncode(user));
    _ref?.read(authStateProvider.notifier).setSession({
      'token': token,
      'user': user,
    });
  }

  // Load Session on App Start
  Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _secureStorage.read(key: 'auth_token');
    final userData = prefs.getString('user_data');

    if (token != null && userData != null) {
      return {"token": token, "user": jsonDecode(userData)};
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: 'auth_token');
    await prefs.remove('user_data');
    _ref?.read(authStateProvider.notifier).setSession(null);
  }

  // Forgot Password
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post("$authBaseUrl/forgot-password", data: {"email": email});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        "$authBaseUrl/reset-password",
        data: {
          "email": email,
          "otp_code": otpCode,
          "new_password": newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Sign in with Google via backend verification
  Future<Map<String, dynamic>> signInWithGoogle({
    required String googleIdToken,
  }) async {
    try {
      final response = await _dio.post(
        "$authBaseUrl/google/verify",
        data: {"google_id_token": googleIdToken},
      );
      final data = Map<String, dynamic>.from(response.data);
      await _saveSession(data);
      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      return e.response?.data['detail'] ??
          "A server error occurred. Please try again.";
    }
    return "Connection failed. Please ensure the backend server is running.";
  }
}
