import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import '../services/call_sound_service.dart';
import '../services/call_notification_service.dart';
import '../services/background_service.dart';
import '../pages/appel_en_cours.dart';
import '../main.dart'; // Import pour navigatorKey

class CallNotificationManager extends StatefulWidget {
  final Widget child;
  const CallNotificationManager({super.key, required this.child});

  @override
  State<CallNotificationManager> createState() =>
      _CallNotificationManagerState();
}

class _CallNotificationManagerState extends State<CallNotificationManager>
    with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();
  Map<String, dynamic>? _incomingCallData;
  bool _dialogVisible = false;
  bool _callActionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocalNotifications();
    _checkAuthAndInitialize();
  }

  Future<void> _initLocalNotifications() async {
    // Assigner le callback AVANT initialize() : quand l'app est relancée
    // par une action de notification (app tuée), la réponse peut être
    // délivrée pendant initialize() — sans callback elle serait perdue.
    CallNotificationService().onResponse = _handleNotificationResponse;
    await CallNotificationService().initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // À la reprise, si un appel attend toujours, afficher la boîte de dialogue
    if (state == AppLifecycleState.resumed &&
        _incomingCallData != null &&
        !_callActionInProgress) {
      _showCallNotification();
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        _incomingCallData = Map<String, dynamic>.from(
          jsonDecode(response.payload!),
        );
      } catch (e) {
        debugPrint(
          '[CallNotificationManager] Payload notification invalide: $e',
        );
      }
    }

    switch (response.actionId) {
      case 'accept':
        _acceptCall();
        break;
      case 'decline':
        _rejectCall();
        break;
      default:
        // Tap sur la notification : ouvrir l'app et afficher le dialogue
        _showCallNotification();
    }
  }

  Future<void> _checkAuthAndInitialize() async {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_webSocketService.isWebRTCConnected) {
        timer.cancel();
        return;
      }

      final accessToken = await AuthService.getToken();
      if (accessToken != null) {
        if (_isTokenExpired(accessToken)) {
          debugPrint(
            '[CallNotificationManager] Token expiré, tentative de reconnexion...',
          );
          await _webSocketService.disconnectWebRTC();
          await Future.delayed(const Duration(seconds: 1));
          return;
        }

        debugPrint(
          '[CallNotificationManager] Utilisateur authentifié, initialisation...',
        );
        await _initializeCallListener();
        // Ne annuler le timer que si la connexion a réussi,
        // sinon réessayer à la prochaine itération
        if (_webSocketService.isWebRTCConnected) {
          timer.cancel();
        }
      }
    });
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      return expDate.isBefore(now);
    } catch (e) {
      debugPrint('[CallNotificationManager] Erreur vérification token: $e');
      return true;
    }
  }

  Future<void> _initializeCallListener() async {
    try {
      debugPrint('[CallNotificationManager] Début initialisation');

      final accessToken = await AuthService.getToken();
      if (accessToken == null) {
        debugPrint('[CallNotificationManager] ERREUR: Token JWT null');
        return;
      }

      await _webSocketService.connectWebRTC(accessToken);
      debugPrint('[CallNotificationManager] WebSocket WebRTC connecté');

      // Garder le processus vivant en arrière-plan (Android) pour que
      // le WebSocket continue de recevoir les appels entrants
      BackgroundService().initAndStart();

      _webSocketService.onIncomingCall.listen((data) {
        debugPrint('[CallNotificationManager] Appel entrant reçu: $data');
        CallSoundService().startRinging();

        final callData = Map<String, dynamic>.from(data);
        final isForeground =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

        if (isForeground) {
          if (mounted) {
            setState(() {
              _incomingCallData = callData;
            });
            _showCallNotification();
          }
        } else {
          // App en arrière-plan : notification système avec actions
          _incomingCallData = callData;
          CallNotificationService().showIncomingCall(
            callerName: _getCallerName(),
            callType: callData['callType'] as String? ?? 'audio',
            callData: callData,
          );
        }
      });

      _webSocketService.onError.listen((error) {
        debugPrint('[CallNotificationManager] ERREUR WebSocket: $error');
      });

      // Si l'appelant raccroche pendant que la boîte de dialogue/notification sonne
      _webSocketService.onCallEnded.listen((data) {
        if (_incomingCallData != null) {
          debugPrint('[CallNotificationManager] Appel terminé par l\'appelant');
          CallSoundService().stopRinging();
          CallNotificationService().cancelIncomingCall();
          if (_dialogVisible) {
            navigatorKey.currentState?.pop();
          }
          setState(() {
            _incomingCallData = null;
          });
        }
      });

      debugPrint('[CallNotificationManager] Initialisation terminée');
    } catch (e, stackTrace) {
      debugPrint('[CallNotificationManager] ERREUR: $e');
      debugPrint('[CallNotificationManager] Stack trace: $stackTrace');
    }
  }

  void _showCallNotification() {
    if (_incomingCallData == null || _dialogVisible) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint(
          '[CallNotificationManager] ERREUR: navigatorKey.currentContext est null',
        );
        return;
      }

      _dialogVisible = true;
      CallNotificationService().cancelIncomingCall();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _IncomingCallDialog(
            callerName: _getCallerName(),
            callType: _incomingCallData!['callType'] as String? ?? 'audio',
            onAccept: () {
              Navigator.of(dialogContext).pop();
              _acceptCall();
            },
            onReject: () {
              Navigator.of(dialogContext).pop();
              _rejectCall();
            },
          );
        },
      ).then((_) {
        _dialogVisible = false;
      });
    });
  }

  String _getCallerName() {
    if (_incomingCallData == null) return 'Inconnu';

    final callerRole = _incomingCallData!['callerRole'];
    final callerEmail = _incomingCallData!['callerEmail'];

    if (callerRole == 'doctor') {
      return 'Dr. $callerEmail';
    } else {
      return callerEmail;
    }
  }

  void _acceptCall() async {
    if (_incomingCallData == null) return;

    _callActionInProgress = true;
    CallSoundService().stopRinging();
    CallNotificationService().cancelIncomingCall();

    final callerId = _incomingCallData!['callerId'];
    final teleconsultationId = _incomingCallData!['teleconsultationId'];
    final callType = _incomingCallData!['callType'];
    final callerRole = _incomingCallData!['callerRole'];

    if (!_webSocketService.isWebRTCConnected) {
      debugPrint(
        '[CallNotificationManager] WebSocket non connecté, attente...',
      );
      int attempts = 0;
      while (!_webSocketService.isWebRTCConnected && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint(
          '[CallNotificationManager] ERREUR: WebSocket toujours non connecté',
        );
        if (mounted) {
          setState(() {
            _incomingCallData = null;
          });
        }
        _callActionInProgress = false;
        return;
      }
    }

    _webSocketService.acceptCall(
      callerId: callerId,
      teleconsultationId: teleconsultationId,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AppelEnCours(
          teleconsultationId: teleconsultationId,
          targetUserId: callerId,
          targetUserRole: callerRole,
          isCaller: false,
          callType: callType?.toString() ?? 'audio',
        ),
      ),
    );

    setState(() {
      _incomingCallData = null;
    });
    _callActionInProgress = false;
  }

  void _rejectCall() async {
    if (_incomingCallData == null) return;

    _callActionInProgress = true;
    CallSoundService().stopRinging();
    CallNotificationService().cancelIncomingCall();

    final callerId = _incomingCallData!['callerId'];
    final teleconsultationId = _incomingCallData!['teleconsultationId'];

    // Comme _acceptCall : le WebSocket est souvent déconnecté quand
    // l'app était en arrière-plan. Attendre sa reconnexion avant
    // d'envoyer le refus, sinon rejectCall échoue silencieusement.
    if (!_webSocketService.isWebRTCConnected) {
      debugPrint(
        '[CallNotificationManager] WebSocket non connecté, attente avant refus...',
      );
      int attempts = 0;
      while (!_webSocketService.isWebRTCConnected && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint(
          '[CallNotificationManager] ERREUR: WebSocket toujours non connecté, refus impossible',
        );
        if (mounted) {
          setState(() {
            _incomingCallData = null;
          });
        }
        _callActionInProgress = false;
        return;
      }
    }

    try {
      _webSocketService.rejectCall(
        callerId: callerId,
        teleconsultationId: teleconsultationId,
      );
      debugPrint('[CallNotificationManager] Appel refusé');
    } catch (e) {
      debugPrint('[CallNotificationManager] ERREUR refus appel: $e');
    }

    setState(() {
      _incomingCallData = null;
    });
    _callActionInProgress = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CallSoundService().stopRinging();
    CallNotificationService().cancelIncomingCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String callType;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingCallDialog({
    required this.callerName,
    required this.callType,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = callType == 'video';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ring_volume, size: 56, color: Color(0xFF8D3188)),
            const SizedBox(height: 16),
            const Text(
              'Appel entrant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              callerName,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isVideo ? 'Appel vidéo' : 'Appel audio',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: Icons.call_end,
                  label: 'Refuser',
                  color: Colors.red,
                  onPressed: onReject,
                ),
                _CallButton(
                  icon: isVideo ? Icons.videocam : Icons.call,
                  label: 'Accepter',
                  color: const Color(0xFF8D3188),
                  onPressed: onAccept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onPressed,
          iconSize: 32,
          style: IconButton.styleFrom(backgroundColor: color),
          icon: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
