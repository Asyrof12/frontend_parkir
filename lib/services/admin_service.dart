import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk admin (dashboard dan statistik)
class AdminService {
  /// Mendapatkan dashboard admin (statistik umum)
  static Future<Map<String, dynamic>> getDashboardAdmin() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dashboard'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
