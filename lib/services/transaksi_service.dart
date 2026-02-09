import 'dart:convert';
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

  /// Transaksi masuk (kendaraan masuk parkir)
  static Future<Map<String, dynamic>> transaksiMasuk(Map<String, dynamic> data) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/masuk'),
        headers: headers,
        body: jsonEncode(data),
      );
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
