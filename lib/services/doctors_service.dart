import 'dart:convert';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/http_interceptor.dart';

class DoctorsService {
  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/auth';
  }

  /// Base des routes admin de gestion des médecins (/api/doctors).
  static String get adminBaseUrl {
    return '${AppConfig.apiBaseUrl}/api/doctors';
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

  // ===== CRUD administrateur (/api/doctors) =====

  /// Tous les médecins, tous statuts confondus.
  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final response = await HttpInterceptor.get(Uri.parse(adminBaseUrl));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Erreur lors du chargement des médecins');
  }

  static Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await HttpInterceptor.get(
      Uri.parse('$adminBaseUrl/specialties'),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Erreur lors du chargement des spécialités');
  }

  static Future<Map<String, dynamic>> createDoctor(
    Map<String, dynamic> data,
  ) async {
    final response = await HttpInterceptor.post(
      Uri.parse(adminBaseUrl),
      body: jsonEncode(data),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(result);
    }
    throw Exception(result['message'] ?? 'Erreur lors de la création');
  }

  static Future<Map<String, dynamic>> updateDoctor(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await HttpInterceptor.put(
      Uri.parse('$adminBaseUrl/$id'),
      body: jsonEncode(data),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(result);
    }
    throw Exception(result['message'] ?? 'Erreur lors de la modification');
  }

  static Future<void> deleteDoctor(String id) async {
    final response = await HttpInterceptor.delete(
      Uri.parse('$adminBaseUrl/$id'),
    );
    if (response.statusCode == 200) return;
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Erreur lors de la suppression');
  }
}
