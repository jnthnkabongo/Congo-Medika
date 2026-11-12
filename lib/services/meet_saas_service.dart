import 'dart:convert';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

class MeetSaaSService {
  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/meet-saas';
  }

  static Future<Map<String, dynamic>> createMeetingForTeleconsultation(
    String teleconsultationId, {
    String mode = 'AUDIO',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teleconsultations/$teleconsultationId/meeting'),
        headers: headers.map((key, value) => MapEntry(key, value.toString())),
        body: jsonEncode({'mode': mode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la création de la réunion',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
