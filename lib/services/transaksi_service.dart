import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk transaksi (petugas)
class TransaksiService {
  /// Mendapatkan semua transaksi
  static Future<Map<String, dynamic>> getTransaksi() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transaksi'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Mendapatkan transaksi by ID
  static Future<Map<String, dynamic>> getTransaksiById(int id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/$id'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Transaksi masuk (kendaraan masuk parkir) — support optional photo
  static Future<Map<String, dynamic>> transaksiMasuk(
    Map<String, dynamic> data, {
    File? photoFile,
  }) async {
    try {
      final token = await ApiConfig.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/transaksi/masuk');

      // Selalu kirim sebagai multipart agar backend bisa terima foto
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Tambahkan field data
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // Attach foto jika ada
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

  /// Transaksi keluar (kendaraan keluar parkir)
  static Future<Map<String, dynamic>> transaksiKeluar(int id, Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/keluar/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
