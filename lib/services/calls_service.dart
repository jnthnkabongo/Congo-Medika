import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/http_interceptor.dart';

class CallsService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.103.126:3001/api/calls';
    } else if (Platform.isAndroid) {
      return 'http://192.168.103.126:3001/api/calls';
    } else if (Platform.isIOS) {
      return 'http://192.168.103.126:3001/api/calls';
    }
    return 'http://192.168.103.126:3001/api/calls';
  }

  static Future<List<Map<String, dynamic>>> getUserCalls() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse(baseUrl));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des appels',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCalls() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/all'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des appels',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static String formatDuration(int? seconds) {
    if (seconds == null) return '-';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  static String formatCallStatus(dynamic status) {
    if (status == null) return 'Inconnu';
    final statusStr = status.toString();
    switch (statusStr.toLowerCase()) {
      case 'calling':
        return 'En cours';
      case 'accepted':
      case 'active':
        return 'Répondu';
      case 'rejected':
        return 'Refusé';
      case 'missed':
        return 'Manqué';
      case 'completed':
        return 'Terminé';
      case 'failed':
        return 'Échoué';
      default:
        return statusStr;
    }
  }

  static String getContactName(
    Map<String, dynamic> call,
    String? currentUserRole,
    String? currentUserId,
  ) {
    final teleconsultation = call['teleconsultation'];

    if (teleconsultation != null && teleconsultation is Map<String, dynamic>) {
      final patient = teleconsultation['patient'];
      final doctor = teleconsultation['doctor'];

      if (currentUserRole == 'patient') {
        if (doctor != null && doctor is Map<String, dynamic>) {
          final firstName = doctor['firstName'] ?? '';
          final lastName = doctor['lastName'] ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return 'Dr. $firstName $lastName';
          }
        }
      } else if (currentUserRole == 'doctor') {
        if (patient != null && patient is Map<String, dynamic>) {
          final firstName = patient['firstName'] ?? '';
          final lastName = patient['lastName'] ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName';
          }
        }
      }
    }

    return 'Inconnu';
  }

  static String getCallDirection(
    Map<String, dynamic> call,
    String? currentUserRole,
    String? currentUserId,
  ) {
    final callerType = call['callerType'];
    final callerId = call['callerId'];

    if (callerType == currentUserRole &&
        callerId?.toString() == currentUserId) {
      return 'Appel sortant';
    } else {
      return 'Appel entrant';
    }
  }
}
