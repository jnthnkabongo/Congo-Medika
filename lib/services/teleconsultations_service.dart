import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

class TeleconsultationsService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.89.126:3001/api/teleconsultations';
    } else if (Platform.isAndroid) {
      return 'http://192.168.89.126:3001/api/teleconsultations';
    } else if (Platform.isIOS) {
      return 'http://192.168.89.126:3001/api/teleconsultations';
    }
    return 'http://192.168.89.126:3001/api/teleconsultations';
  }

  // Créer une téléconsultation
  static Future<Map<String, dynamic>> createTeleconsultation({
    required int appointmentId,
    required int patientId,
    required int doctorId,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
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
        throw Exception(data['message'] ?? 'Erreur lors de la création de la téléconsultation');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les téléconsultations du patient
  static Future<List<Map<String, dynamic>>> getPatientTeleconsultations() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/patient'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération des téléconsultations');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les téléconsultations du docteur
  static Future<List<Map<String, dynamic>>> getDoctorTeleconsultations() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/doctor'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération des téléconsultations');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer une téléconsultation par ID
  static Future<Map<String, dynamic>> getTeleconsultationById(String id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

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
