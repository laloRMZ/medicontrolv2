import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:3000';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<bool> isTokenExpired() async {
    final token = await _getToken();
    if (token == null) return true;
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<({AppUser user, String token, String refreshToken})> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AppUser.fromJson(data['user']);
        final token = data['token'] as String;
        final refreshToken = data['refreshToken'] as String;

        await _saveTokens(token, refreshToken);
        await _saveUser(user);

        return (user: user, token: token, refreshToken: refreshToken);
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de login: $e');
    }
  }

  static Future<({AppUser user, String token})> register(
    String fullName,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AppUser.fromJson(data['user']);
        final token = data['token'] as String;
        final refreshToken = data['refreshToken'] as String;

        await _saveTokens(token, refreshToken);
        await _saveUser(user);

        return (user: user, token: token);
      } else {
        throw Exception('Error en registro: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de registro: $e');
    }
  }

  static Future<AppUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(userData));
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  static Future<AppUser?> getCurrentUser() async {
    final token = await _getToken();
    if (token == null || await isTokenExpired()) {
      return null;
    }
    return getStoredUser();
  }
}
