import 'dart:convert';
import '../config/app_config.dart';
import 'package:frontend/services/http_interceptor.dart';

class TeleconsultationsService {
  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/teleconsultations';
  }

  // Créer une téléconsultation
  static Future<Map<String, dynamic>> createTeleconsultation({
    required int appointmentId,
    required int patientId,
    required int doctorId,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'appointmentId': appointmentId,
          'patientId': patientId,
          'doctorId': doctorId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Erreur lors de la création de la téléconsultation',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les téléconsultations du patient
  static Future<List<Map<String, dynamic>>>
  getPatientTeleconsultations() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/patient'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ??
              'Erreur lors de la récupération des téléconsultations',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les téléconsultations du docteur
  static Future<List<Map<String, dynamic>>> getDoctorTeleconsultations() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/doctor'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ??
              'Erreur lors de la récupération des téléconsultations',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer une téléconsultation par ID
  static Future<Map<String, dynamic>> getTeleconsultationById(String id) async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/$id'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Téléconsultation non trouvée');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
