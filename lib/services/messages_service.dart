import 'dart:convert';
import '../config/app_config.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/http_interceptor.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MessagesService {
  static String get baseUrl {
    return '${AppConfig.apiBaseUrl}/api/messages';
  }

  /// Upload un fichier audio et retourne l'URL complète du fichier
  /// hébergé par le backend (ex: http://serveur/uploads/audio/xxx.m4a).
  static Future<String> uploadAudio(String filePath) async {
    final fileName = filePath.split('/').last;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-audio'),
    );

    // MultipartRequest définit lui-même le Content-Type (avec boundary)
    final headers = await AuthService.getAuthHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
        contentType: MediaType('audio', 'mp4'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      await AuthService.logout();
      onAuthExpired?.call();
      throw Exception('Non autorisé');
    }

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final path = data['url'] as String;
      // Le backend renvoie un chemin relatif (/uploads/...) : on le
      // préfixe avec l'origine de l'API.
      return path.startsWith('http')
          ? path
          : '${AppConfig.apiBaseUrl}$path';
    }
    throw Exception(
      data['message'] ?? 'Erreur lors de l\'upload du message audio',
    );
  }

  static Future<List<Map<String, dynamic>>> getMessagesByRoomId(
    String roomId,
  ) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl?roomId=$roomId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((message) => Map<String, dynamic>.from(message))
            .toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la récupération des messages',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
