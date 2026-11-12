import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

// Callback pour la redirection (sera défini dans main.dart)
void Function()? onAuthExpired;

class HttpInterceptor {
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeadersWithCheck(headers);
    final response = await http.get(url, headers: authHeaders);
    await _handleUnauthorizedResponse(response);
    return response;
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final authHeaders = await _getAuthHeadersWithCheck(headers);
    final response = await http.post(url, headers: authHeaders, body: body);
    await _handleUnauthorizedResponse(response);
    return response;
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final authHeaders = await _getAuthHeadersWithCheck(headers);
    final response = await http.put(url, headers: authHeaders, body: body);
    await _handleUnauthorizedResponse(response);
    return response;
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeadersWithCheck(headers);
    final response = await http.delete(url, headers: authHeaders);
    await _handleUnauthorizedResponse(response);
    return response;
  }

  static Future<Map<String, String>> _getAuthHeadersWithCheck(
    Map<String, String>? additionalHeaders,
  ) async {
    // getToken() rafraîchit silencieusement le token s'il est expiré ;
    // il ne retourne null que si le refresh token est aussi invalide.
    final token = await AuthService.getToken();

    if (token == null) {
      await AuthService.logout();
      onAuthExpired?.call();
      throw Exception('Token expiré');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
    return headers;
  }

  static Future<void> _handleUnauthorizedResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 401) {
      // Token invalide ou expiré, rediriger vers login
      await AuthService.logout();
      onAuthExpired?.call();
      throw Exception('Non autorisé');
    }
  }
}
