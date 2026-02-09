import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk authentication (login, logout)
class AuthService {
  /// Login dengan username dan password
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔐 Attempting login to: ${ApiConfig.baseUrl}/auth/login');
      print('📝 Username: $username');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Login successful!');
        await ApiConfig.saveToken(data['token']);
        await ApiConfig.saveUser(data['user']);
        return {'success': true, 'data': data};
      } else {
        print('❌ Login failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      print('💥 Exception during login: $e');
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
        headers: headers,
      );

      await ApiConfig.clearData();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Logout berhasil'};
      } else {
        return {'success': true, 'message': 'Logout berhasil (local)'};
      }
    } catch (e) {
      await ApiConfig.clearData();
      return {'success': true, 'message': 'Logout berhasil (local)'};
    }
  }

  /// Mendapatkan token
  static Future<String?> getToken() => ApiConfig.getToken();

  /// Mendapatkan user data
  static Future<Map<String, dynamic>?> getUser() => ApiConfig.getUser();
}
