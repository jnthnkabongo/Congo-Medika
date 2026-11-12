import 'dart:convert';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // static String baseUrl = 'http://localhost:3001/api/auth';

  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/auth';
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
          'address': address,
          'dateOfBirth': dateOfBirth,
          'specialtyId': specialtyId,
          'licenseNumber': licenseNumber,
          'bio': bio,
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
    String? role,
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

  static Future<Map<String, dynamic>> resendLoginCode({
    required String email,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-login-code'),
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
    String? role,
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

  /// Vérifie si la chaîne JWT est expirée (sans effet de bord).
  static bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalizedPayload = payload
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      final paddedPayload = normalizedPayload.padRight(
        normalizedPayload.length + (4 - normalizedPayload.length % 4) % 4,
        '=',
      );
      final decoded = utf8.decode(base64.decode(paddedPayload));
      final payloadData = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = payloadData['exp'];
      if (exp == null) return true;

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      return true;
    }
  }

  /// Échange le refresh token contre une nouvelle paire de tokens.
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['accessToken']);
      if (data['refreshToken'] != null) {
        await prefs.setString(_refreshTokenKey, data['refreshToken']);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retourne un access token VALIDE : si celui stocké est expiré,
  /// tente un refresh silencieux via le refresh token. Retourne null
  /// (et nettoie la session) seulement si le refresh échoue aussi.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_tokenKey);
    if (token == null) return null;
    if (!_isJwtExpired(token)) return token;

    final refreshed = await refreshAccessToken();
    if (!refreshed) {
      await logout();
      return null;
    }
    token = prefs.getString(_tokenKey);
    return token;
  }

  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return true;
    return _isJwtExpired(token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
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
