import 'dart:convert';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

class DoctorsService {
  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/auth';
  }

  static Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des médecins',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
