import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk tarif management (CRUD tarif)
class TarifService {
  /// Mendapatkan semua tarif
  static Future<Map<String, dynamic>> getTarif() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tarif'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Mendapatkan tarif by ID
  static Future<Map<String, dynamic>> getTarifById(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tarif/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Membuat tarif baru
  static Future<Map<String, dynamic>> createTarif(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tarif'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Update tarif
  static Future<Map<String, dynamic>> updateTarif(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/tarif/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Delete tarif
  static Future<Map<String, dynamic>> deleteTarif(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/tarif/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}