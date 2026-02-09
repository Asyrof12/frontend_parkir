import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk area management (CRUD area)
class AreaService {
  /// Mendapatkan semua area
  static Future<Map<String, dynamic>> getAreas() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/area'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Mendapatkan area by ID
  static Future<Map<String, dynamic>> getAreaById(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/area/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Membuat area baru
  static Future<Map<String, dynamic>> createArea(Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/area'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Update area
  static Future<Map<String, dynamic>> updateArea(int id, Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/area/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Delete area
  static Future<Map<String, dynamic>> deleteArea(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/area/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
