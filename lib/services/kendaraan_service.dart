import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk kendaraan management (CRUD kendaraan) dengan dukungan upload foto
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

  /// Membuat kendaraan baru — kirim sebagai multipart/form-data (untuk support foto)
  static Future<Map<String, dynamic>> createKendaraan(
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    try {
      final token = await ApiConfig.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/kendaraan');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Form fields
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // Attach photo jika ada
      if (photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Update kendaraan — kirim sebagai multipart/form-data
  static Future<Map<String, dynamic>> updateKendaraan(
    int id,
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    try {
      final token = await ApiConfig.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/kendaraan/$id');

      // http.MultipartRequest tidak support PUT di beberapa server, kita override method
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-HTTP-Method-Override'] = 'PUT';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      var streamed = await request.send();
      var response = await http.Response.fromStream(streamed);

      // Jika method override tidak didukung, coba PUT manual pakai bytes
      if (response.statusCode == 404 || response.statusCode == 405) {
        return _updateWithPut(id, data, photoFile: photoFile);
      }
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Fallback: Update dengan PUT multipart request sesungguhnya
  static Future<Map<String, dynamic>> _updateWithPut(
    int id,
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    try {
      final token = await ApiConfig.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/kendaraan/$id');
      final request = http.MultipartRequest('PUT', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      if (photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
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
