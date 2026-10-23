import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      return;
    }
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      return;
    }
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    }
  }
}
