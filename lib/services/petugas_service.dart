import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk petugas (dashboard dan transaksi)
class PetugasService {
  /// Mendapatkan dashboard petugas (statistik hari ini)
  static Future<Map<String, dynamic>> getDashboardPetugas() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/petugas/dashboard'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
