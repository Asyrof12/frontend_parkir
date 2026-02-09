import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk owner (laporan dan dashboard)
class OwnerService {
  /// Mendapatkan rekap transaksi berdasarkan tanggal
  static Future<Map<String, dynamic>> getRekapTransaksi(String startDate, String endDate) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/owner/rekap?start_date=$startDate&end_date=$endDate'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  /// Mendapatkan dashboard owner (statistik)
  static Future<Map<String, dynamic>> getDashboardOwner() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/owner/dashboard'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
