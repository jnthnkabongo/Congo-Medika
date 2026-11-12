import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Affiche une notification système « Appel entrant » quand l'application
/// est en arrière-plan (le WebSocket peut rester actif un certain temps).
/// Les actions Accepter/Refuser ouvrent l'application et sont traitées
/// dans l'isolate principal via [onResponse].
class CallNotificationService {
  static final CallNotificationService _instance =
      CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'incoming_calls';
  static const int _notificationId = 1001;

  bool _initialized = false;

  /// Callback invoqué quand l'utilisateur touche la notification ou une action.
  void Function(NotificationResponse response)? onResponse;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    final androidSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'incoming_call',
          actions: [
            DarwinNotificationAction.plain('decline', 'Refuser'),
            DarwinNotificationAction.plain('accept', 'Accepter'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    // Android 13+ : permission POST_NOTIFICATIONS demandée au runtime
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[CallNotificationService] Initialisé');
  }

  Future<void> showIncomingCall({
    required String callerName,
    required String callType,
    required Map<String, dynamic> callData,
  }) async {
    if (!_initialized) return;

    final isVideo = callType == 'video';

    await _plugin.show(
      id: _notificationId,
      title: isVideo ? 'Appel vidéo entrant' : 'Appel audio entrant',
      body: callerName,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Appels entrants',
          channelDescription: 'Notifications pour les appels entrants',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          // Le son est joué par CallSoundService (audioplayers)
          playSound: false,
          enableVibration: true,
          actions: const [
            AndroidNotificationAction(
              'decline',
              'Refuser',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'accept',
              'Accepter',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          // Le son est joué par CallSoundService (audioplayers)
          presentSound: false,
          categoryIdentifier: 'incoming_call',
        ),
      ),
      payload: jsonEncode(callData),
    );

    debugPrint('[CallNotificationService] Notification appel entrant affichée');
  }

  Future<void> cancelIncomingCall() async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId);
  }

  void _handleResponse(NotificationResponse response) {
    debugPrint(
      '[CallNotificationService] Réponse notification: '
      'action=${response.actionId}, payload=${response.payload}',
    );
    onResponse?.call(response);
  }
}
