import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive data like tokens
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  // Keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  
  // Token methods
  
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }
  
  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }
  
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  // User info methods
  
  static Future<void> saveUserInfo({
    required String userId,
    required String role,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userRoleKey, value: role);
  }
  
  static Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }
  
  static Future<String?> getUserRole() async {
    return _storage.read(key: _userRoleKey);
  }
  
  // Clear all
  
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
