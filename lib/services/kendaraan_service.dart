import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk kendaraan management (CRUD kendaraan)
class KendaraanService {
  /// Mendapatkan semua kendaraan
  static Future<Map<String, dynamic>> getKendaraan() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kendaraan'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Mendapatkan kendaraan by ID
  static Future<Map<String, dynamic>> getKendaraanById(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kendaraan/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Membuat kendaraan baru
  static Future<Map<String, dynamic>> createKendaraan(Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/kendaraan'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Update kendaraan
  static Future<Map<String, dynamic>> updateKendaraan(int id, Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/kendaraan/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Delete kendaraan
  static Future<Map<String, dynamic>> deleteKendaraan(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/kendaraan/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
