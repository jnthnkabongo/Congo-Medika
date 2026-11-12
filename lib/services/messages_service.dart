import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/http_interceptor.dart';

class MessagesService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://10.235.140.126:3001/api/messages';
    } else if (Platform.isAndroid) {
      return 'http://10.235.140.126:3001/api/messages';
    } else if (Platform.isIOS) {
      return 'http://10.235.140.126:3001/api/messages';
    }
    return 'http://10.235.140.126:3001/api/messages';
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
