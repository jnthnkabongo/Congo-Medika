import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'appointments_service.dart';

/// Planifie des notifications locales « rappel de rendez-vous » 5 minutes
/// avant le début du rendez-vous. Les rappels persistent dans l'OS même
/// application fermée (zonedSchedule).
class AppointmentReminderService {
  static final AppointmentReminderService _instance =
      AppointmentReminderService._internal();
  factory AppointmentReminderService() => _instance;
  AppointmentReminderService._internal();

  static const int _reminderMinutesBefore = 5;
  static const String _channelId = 'appointment_reminders';
  static const String _prefsKey = 'scheduled_appointment_reminders';
  static const int _notificationIdBase = 100000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timeZonesInitialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    await _initTimeZones();
    _initialized = true;
    debugPrint('[AppointmentReminder] Service initialisé');
  }

  Future<void> _initTimeZones() async {
    if (_timeZonesInitialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[AppointmentReminder] Fuseau horaire inconnu: $e');
      tz.setLocalLocation(tz.UTC);
    }
    _timeZonesInitialized = true;
  }

  /// Resynchronise les rappels avec la liste des rendez-vous :
  /// annule les anciens et planifie ceux des rendez-vous à venir.
  Future<void> syncReminders(
    List<Map<String, dynamic>> appointments,
  ) async {
    try {
      await initialize();
      await _cancelAllScheduled();

      final now = DateTime.now();
      final scheduledIds = <int>[];

      for (final appointment in appointments) {
        final start = _appointmentStart(appointment);
        if (start == null) continue;

        final status = appointment['status']?.toString().toLowerCase();
        if (status == 'cancelled' ||
            status == 'completed' ||
            status == 'no_show') {
          continue;
        }

        final reminderTime = start.subtract(
          const Duration(minutes: _reminderMinutesBefore),
        );
        // Le rappel est déjà passé (ou trop proche pour être planifié)
        if (!reminderTime.isAfter(now)) continue;

        final id = _notificationId(appointment);
        final doctorName = AppointmentsService.getDoctorName(appointment);
        final reason = appointment['reason'];
        final reasonText = reason is String && reason.isNotEmpty
            ? reason
            : 'Consultation';

        await _scheduleReminder(
          id: id,
          reminderTime: reminderTime,
          title: 'Rendez-vous dans $_reminderMinutesBefore minutes',
          body: 'Votre rendez-vous avec $doctorName ($reasonText) '
              'commence à ${_formatTime(start)}.',
          payload: jsonEncode({
            'type': 'appointment',
            'appointmentId': appointment['id'],
          }),
        );
        scheduledIds.add(id);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        scheduledIds.map((id) => id.toString()).toList(),
      );

      debugPrint(
        '[AppointmentReminder] ${scheduledIds.length} rappel(s) planifié(s)',
      );
    } catch (e) {
      debugPrint('[AppointmentReminder] Erreur sync rappels: $e');
    }
  }

  Future<void> _scheduleReminder({
    required int id,
    required DateTime reminderTime,
    required String title,
    required String body,
    required String payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Rappels de rendez-vous',
        channelDescription:
            'Notifications de rappel avant un rendez-vous médical',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException {
      // Permission d'alarme exacte refusée : retomber sur un rappel
      // approximatif plutôt que d'abandonner.
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> _cancelAllScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? const [];
    for (final idStr in ids) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await _plugin.cancel(id: id);
      }
    }
    await prefs.remove(_prefsKey);
  }

  int _notificationId(Map<String, dynamic> appointment) {
    final rawId = appointment['id'];
    final numericId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? rawId.hashCode.abs();
    return _notificationIdBase + numericId.abs() % 1000000000;
  }

  /// Reconstruit la date/heure de début du rendez-vous à partir des
  /// champs `appointmentDate` et `startTime` (formats variables :
  /// 'YYYY-MM-DD', ISO complet, 'HH:MM', DateTime, map Prisma...).
  DateTime? _appointmentStart(Map<String, dynamic> appointment) {
    // Cas où startTime contient déjà date + heure (ISO complet)
    final startTime = appointment['startTime'];
    if (startTime is String && startTime.contains('T')) {
      final parsed = DateTime.tryParse(startTime);
      if (parsed != null) return parsed.toLocal();
    }

    final day = _parseDay(appointment['appointmentDate']);
    if (day == null) return null;

    int? hour;
    int? minute;
    if (startTime is String) {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(startTime);
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
      }
    } else if (startTime is DateTime) {
      hour = startTime.hour;
      minute = startTime.minute;
    } else if (startTime is Map<String, dynamic>) {
      final nested = startTime['date'];
      if (nested is String && nested.contains('T')) {
        final parsed = DateTime.tryParse(nested);
        if (parsed != null) return parsed.toLocal();
      }
      if (nested is String) {
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(nested);
        if (match != null) {
          hour = int.parse(match.group(1)!);
          minute = int.parse(match.group(2)!);
        }
      }
    }

    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Extrait le jour (année/mois/jour) en ignorant la partie heure pour
  /// éviter les décalages de fuseau horaire sur les dates 'YYYY-MM-DD'
  /// ou ISO avec 'Z'.
  DateTime? _parseDay(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) {
      return DateTime(dateValue.year, dateValue.month, dateValue.day);
    }
    if (dateValue is String) {
      final datePart =
          dateValue.length >= 10 ? dateValue.substring(0, 10) : dateValue;
      return DateTime.tryParse(datePart);
    }
    if (dateValue is Map<String, dynamic>) {
      return _parseDay(dateValue['date']);
    }
    return null;
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
