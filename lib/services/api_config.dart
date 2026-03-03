import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/**
 * Konfigurasi API Pusat
 * Mengatur Base URL, header autentikasi, dan pengelolaan token JWT 
 * menggunakan SharedPreferences.
 */
class ApiConfig {
  // URL ngrok untuk testing/production
  static const String baseUrl = 'https://dishonestly-nondistracted-vania.ngrok-free.dev/api';

  // Untuk development lokal:
  // static const String baseUrl = 'http://localhost:3000/api';

  /// Mendapatkan headers dengan token authorization
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Skip ngrok warning page
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle response dari API
  static Map<String, dynamic> handleResponse(http.Response response) {
    final body = response.body.trim();

    // Deteksi jika server mengembalikan HTML (mis. ngrok warning page / server error)
    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      return {
        'success': false,
        'message': 'Server mengembalikan halaman HTML. Pastikan backend berjalan dan URL API benar. (HTTP ${response.statusCode})',
      };
    }

    final data = jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Merge success: false with the original data to preserve extra flags like hasHistory
      return {
        'success': false,
        ...data,
      };
    }
  }

  /// Mendapatkan token dari SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Menyimpan token ke SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  /// Menyimpan user data ke SharedPreferences
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  /// Mendapatkan user data dari SharedPreferences
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  /// Clear semua data (untuk logout)
  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

