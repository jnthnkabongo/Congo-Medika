import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/http_interceptor.dart';

class AppointmentsService {
  static String get baseUrl {
    return 'http://192.168.103.126:3001/api/appointments';
  }

  static Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse(baseUrl));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des rendez-vous',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllAppointments() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/all'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des rendez-vous',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> createAppointment({
    required int doctorId,
    required String appointmentDate,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'doctorId': doctorId,
          'appointmentDate': appointmentDate,
          'startTime': startTime,
          'endTime': endTime,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la création du rendez-vous',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> getAppointmentById(String id) async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$baseUrl/$id'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Rendez-vous non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAppointment({
    required String id,
    String? appointmentDate,
    String? startTime,
    String? endTime,
    String? reason,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (appointmentDate != null) body['appointmentDate'] = appointmentDate;
      if (startTime != null) body['startTime'] = startTime;
      if (endTime != null) body['endTime'] = endTime;
      if (reason != null) body['reason'] = reason;
      if (status != null) body['status'] = status;

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/$id'),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAppointment(String id) async {
    try {
      final response = await HttpInterceptor.delete(Uri.parse('$baseUrl/$id'));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static String formatAppointmentStatus(dynamic status) {
    if (status == null) return 'Inconnu';
    final statusStr = status.toString();
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      case 'no_show':
        return 'Absent';
      default:
        return statusStr;
    }
  }

  static String getDoctorName(Map<String, dynamic> appointment) {
    final doctor = appointment['doctor'];
    if (doctor != null && doctor is Map<String, dynamic>) {
      final firstName = doctor['firstName'] ?? '';
      final lastName = doctor['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return 'Dr. $firstName $lastName';
      }
    }
    return 'Médecin inconnu';
  }

  static String getPatientName(Map<String, dynamic> appointment) {
    final patient = appointment['patient'];
    if (patient != null && patient is Map<String, dynamic>) {
      final firstName = patient['firstName'] ?? '';
      final lastName = patient['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
    }
    return 'Patient inconnu';
  }

  static String formatDate(dynamic dateString) {
    DateTime date;
    if (dateString is DateTime) {
      date = dateString;
    } else if (dateString is String) {
      date = DateTime.parse(dateString);
    } else if (dateString is Map<String, dynamic>) {
      // Si c'est un objet Prisma DateTime, extraire la date
      final dateValue = dateString['date'];
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Date inconnue';
      }
    } else {
      return 'Date inconnue';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Aujourd\'hui';
    } else if (appointmentDate == tomorrow) {
      return 'Demain';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return months[month - 1];
  }

  static String formatTime(DateTime time) {
    if (time.year == 1970) {
      // Si c'est une heure stockée dans une date fictive (1970), extraire juste l'heure
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static Color getStatusColor(dynamic status) {
    if (status == null) return Colors.grey;
    final statusStr = status.toString();
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
