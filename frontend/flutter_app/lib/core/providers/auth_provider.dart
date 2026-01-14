import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../storage/secure_storage.dart';

/// User model
class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final String? expertiseDomain;
  final String? qualification;
  final int? experienceYears;
  final String? location;
  
  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.expertiseDomain,
    this.qualification,
    this.experienceYears,
    this.location,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      status: json['status'],
      expertiseDomain: json['expertise_domain'],
      qualification: json['qualification'],
      experienceYears: json['experience_years'],
      location: json['location'],
    );
  }
  
  bool get isFarmer => role == 'FARMER';
  bool get isExpert => role == 'EXPERT';
  bool get isApprovedExpert => isExpert && status == 'ACTIVE';
  bool get isPendingExpert => isExpert && status == 'PENDING';
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient _apiClient;
  
  AuthNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      if (isLoggedIn) {
        await fetchCurrentUser();
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }
  
  Future<void> fetchCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiClient.get(ApiConfig.me);
      final user = User.fromJson(response.data);
      await SecureStorage.saveUserInfo(userId: user.id, role: user.role);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }
  
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiClient.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );
      
      await SecureStorage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      
      final user = User.fromJson(response.data['user']);
      await SecureStorage.saveUserInfo(userId: user.id, role: user.role);
      
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      state = AsyncValue.error(message, StackTrace.current);
    }
  }
  
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
    String? expertiseDomain,
    String? qualification,
    int? experienceYears,
    String? location,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiClient.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'expertise_domain': expertiseDomain,
          'qualification': qualification,
          'experience_years': experienceYears,
          'location': location,
        },
      );
      
      await SecureStorage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      
      final user = User.fromJson(response.data['user']);
      await SecureStorage.saveUserInfo(userId: user.id, role: user.role);
      
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed';
      state = AsyncValue.error(message, StackTrace.current);
    }
  }
  
  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AsyncValue.data(null);
  }
}

/// Provider for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

/// Convenience provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
