import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service untuk log activity (admin)
class LogService {
  /// Mendapatkan semua log activity
  static Future<Map<String, dynamic>> getLogs() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/log'),
        headers: headers,
      );
      return ApiConfig.handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
