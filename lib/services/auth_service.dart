import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // static String baseUrl = 'http://localhost:3001/api/auth';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.89.126:3001/api/auth';
    } else if (Platform.isAndroid) {
      return 'http://192.168.89.126:3001/api/auth';
    } else if (Platform.isIOS) {
      return 'http://192.168.89.126:3001/api/auth';
    }
    return 'http://192.168.89.126:3001/api/auth';
  }

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user';

  // Getters publics pour accéder aux clés
  static String get tokenKey => _tokenKey;
  static String get refreshTokenKey => _refreshTokenKey;
  static String get userKey => _userKey;

  // Inscription
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
    required String gender,
    String? address,
    String? dateOfBirth,
    String? specialtyId,
    String? licenseNumber,
    String? bio,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'phone': phone.trim(),
          'role': role,
          'gender': gender,
          if (address != null) 'address': address,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (specialtyId != null) 'specialtyId': specialtyId,
          if (licenseNumber != null) 'licenseNumber': licenseNumber,
          if (bio != null) 'bio': bio,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Vérification de l'email
  static Future<Map<String, dynamic>> verifyEmail({
    required String challengeId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'challengeId': challengeId, 'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Renvoyer le code de vérification
  static Future<Map<String, dynamic>> resendVerification({
    required String email,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'role': role}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors du renvoi');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Email ou mot de passe incorrect');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Vérification du code de connexion (2FA)
  static Future<Map<String, dynamic>> verifyLoginCode({
    required String challengeId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-login-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'challengeId': challengeId, 'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Sauvegarder des données utilisateur
  static Future<void> sauvegardeDonneesUser(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else {
      await prefs.setString(key, jsonEncode(value));
    }
  }

  // Récupérer des données utilisateur
  static Future<dynamic> getDonneesUser(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data != null) {
      try {
        return jsonDecode(data);
      } catch (e) {
        return data;
      }
    }
    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
