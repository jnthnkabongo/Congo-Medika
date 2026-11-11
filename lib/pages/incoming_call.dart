import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'appel_en_cours.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import '../main.dart'; // Import pour navigatorKey

class IncomingCall extends StatefulWidget {
  const IncomingCall({super.key});

  @override
  State<IncomingCall> createState() => _IncomingCallState();
}

class _IncomingCallState extends State<IncomingCall> {
  final WebSocketService _webSocketService = WebSocketService();

  Map<String, dynamic>? _incomingCallData;

  @override
  void initState() {
    super.initState();
    _checkAuthAndInitialize();
  }

  Future<void> _checkAuthAndInitialize() async {
    // Vérifier périodiquement si l'utilisateur est authentifié
    // et initialiser la connexion WebSocket quand il l'est
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Vérifier si déjà connecté
      if (_webSocketService.isWebRTCConnected) {
        timer.cancel();
        return;
      }

      // Vérifier si l'utilisateur est authentifié
      final accessToken = await AuthService.getToken();
      if (accessToken != null) {
        // Vérifier si le token est expiré
        if (_isTokenExpired(accessToken)) {
          debugPrint(
            '[IncomingCall] Token expiré, tentative de reconnexion...',
          );
          // Essayer de rafraîchir le token ou se reconnecter
          await _webSocketService.disconnectWebRTC();
          await Future.delayed(const Duration(seconds: 1));
          return; // Le timer continuera à vérifier
        }

        debugPrint('[IncomingCall] Utilisateur authentifié, initialisation...');
        await _initializeIncomingCallListener();
        timer.cancel();
      }
    });
  }

  // Vérifier si le token JWT est expiré
  bool _isTokenExpired(String token) {
    try {
      // Décoder le token JWT (partie payload)
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Décoder le payload (base64)
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      // Vérifier l'expiration
      final exp = payload['exp'];
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      return expDate.isBefore(now);
    } catch (e) {
      debugPrint('[IncomingCall] Erreur vérification token: $e');
      return true; // En cas d'erreur, considérer comme expiré
    }
  }

  Future<void> _initializeIncomingCallListener() async {
    try {
      debugPrint(
        '[IncomingCall] Début initialisation de l\'écoute des appels entrants',
      );

      // Récupérer le token JWT
      debugPrint('[IncomingCall] Récupération du token JWT...');
      final accessToken = await AuthService.getToken();
      if (accessToken == null) {
        debugPrint('[IncomingCall] ERREUR: Token JWT null');
        return;
      }
      debugPrint('[IncomingCall] Token JWT récupéré avec succès');

      // Connecter au WebSocket WebRTC
      debugPrint('[IncomingCall] Connexion au WebSocket WebRTC...');
      await _webSocketService.connectWebRTC(accessToken);
      debugPrint('[IncomingCall] WebSocket WebRTC connecté');

      // Écouter les appels entrants
      _webSocketService.onIncomingCall.listen((data) {
        debugPrint('[IncomingCall] Appel entrant reçu: $data');
        if (mounted) {
          setState(() {
            _incomingCallData = data;
          });
          _showIncomingCallDialog();
        }
      });

      // Écouter les erreurs WebSocket
      _webSocketService.onError.listen((error) {
        debugPrint('[IncomingCall] ERREUR WebSocket: $error');
      });

      debugPrint('[IncomingCall] Initialisation terminée avec succès');
    } catch (e, stackTrace) {
      debugPrint('[IncomingCall] ERREUR lors de l\'initialisation: $e');
      debugPrint('[IncomingCall] Stack trace: $stackTrace');
    }
  }

  void _showIncomingCallDialog() {
    if (_incomingCallData == null) return;

    debugPrint('[IncomingCall] Tentative affichage boîte de dialogue');
    debugPrint(
      '[IncomingCall] navigatorKey.currentContext: ${navigatorKey.currentContext}',
    );

    // Utiliser ScaffoldMessenger pour afficher une notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint(
          '[IncomingCall] ERREUR: navigatorKey.currentContext est null',
        );
        return;
      }

      debugPrint(
        '[IncomingCall] Contexte trouvé, affichage de la notification',
      );

      // Afficher une notification avec ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _incomingCallData!['callType'] == 'video'
                    ? 'Appel vidéo entrant'
                    : 'Appel audio entrant',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_getCallerName()),
            ],
          ),
          backgroundColor: const Color(0xFF8D3188),
          duration: const Duration(seconds: 30),
          action: SnackBarAction(
            label: 'Accepter',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _acceptCall();
            },
          ),
        ),
      );

      debugPrint('[IncomingCall] Notification affichée');
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

    final callerId = _incomingCallData!['callerId'];
    final teleconsultationId = _incomingCallData!['teleconsultationId'];
    final callType = _incomingCallData!['callType'];
    final callerRole = _incomingCallData!['callerRole'];

    // S'assurer que le WebSocket est connecté avant d'accepter
    debugPrint(
      '[IncomingCall] Vérification connexion WebSocket avant acceptation...',
    );
    if (!_webSocketService.isWebRTCConnected) {
      debugPrint('[IncomingCall] WebSocket non connecté, attente...');
      int attempts = 0;
      while (!_webSocketService.isWebRTCConnected && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint('[IncomingCall] ERREUR: WebSocket toujours non connecté');
        return;
      }
      debugPrint(
        '[IncomingCall] WebSocket connecté après $attempts tentatives',
      );
    }

    // Accepter l'appel via WebSocket
    _webSocketService.acceptCall(
      callerId: callerId,
      teleconsultationId: teleconsultationId,
    );
    debugPrint('[IncomingCall] Appel accepté');

    // Attendre un peu que le patient envoie l'offre SDP
    // et que la connexion soit stabilisée
    debugPrint('[IncomingCall] Attente avant navigation...');
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('[IncomingCall] Navigation vers page d\'appel');

    // Ne PAS déconnecter le WebSocket - AppelEnCours réutilisera la connexion existante
    // pour éviter de perdre la connexion avant de recevoir l'offre

    // Naviguer vers la page d'appel en utilisant le Navigator global
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
  }

  @override
  void dispose() {
    // Ne pas déconnecter le WebSocket ici pour éviter les déconnexions automatiques
    // Le WebSocket doit rester connecté pendant que l'utilisateur navigue
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ce widget est invisible - il écoute juste les appels entrants
    // et affiche des dialogues quand un appel arrive
    return const SizedBox.shrink();
  }
}
