import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// IDs de la notification persistante du service de premier plan
const String _channelId = 'congomedika_background';
const int _notificationId = 999;

/// Callback exécuté dans l'isolate de fond.
/// Doit rester une fonction top-level annotée @pragma('vm:entry-point').
/// Le service sert uniquement à empêcher Android de tuer le processus
/// (et donc le WebSocket des appels) quand l'app est en arrière-plan.
@pragma('vm:entry-point')
Future<void> onBackgroundStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('stop').listen((_) {
      service.stopSelf();
    });
  }
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _initialized = false;

  /// Démarre le service de premier plan Android pour maintenir l'app
  /// (et la connexion WebRTC) vivante en arrière-plan.
  /// Sans effet sur le web ; sur iOS l'impact est très limité.
  Future<void> initAndStart() async {
    if (_initialized || kIsWeb || !Platform.isAndroid) return;

    try {
      // Le service de premier plan affiche sa propre notification :
      // le canal doit être créé avant configure().
      const channel = AndroidNotificationChannel(
        _channelId,
        'CongoMedika - Appels',
        description:
            'Maintient la connexion pour recevoir les appels entrants',
        importance: Importance.low,
      );
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundStart,
          autoStart: true,
          autoStartOnBoot: true,
          isForegroundMode: true,
          notificationChannelId: _channelId,
          initialNotificationTitle: 'CongoMedika',
          initialNotificationContent:
              'Disponible pour recevoir des appels',
          foregroundServiceNotificationId: _notificationId,
          foregroundServiceTypes: const [
            AndroidForegroundType.dataSync,
          ],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onBackgroundStart,
          onBackground: (_) async => true,
        ),
      );

      await service.startService();
      _initialized = true;
      debugPrint('[BackgroundService] Service démarré');
    } catch (e) {
      debugPrint('[BackgroundService] ERREUR: $e');
    }
  }
}
