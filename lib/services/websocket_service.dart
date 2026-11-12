import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  socket_io.Socket? _socket;
  socket_io.Socket? _webrtcSocket;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://10.235.140.126:3001';
    } else if (Platform.isAndroid) {
      return 'http://10.235.140.126:3001';
    } else if (Platform.isIOS) {
      return 'http://10.235.140.126:3001';
    }
    return 'http://10.235.140.126:3001';
  }

  // Streams pour les événements
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _roomJoinedController = StreamController<String>.broadcast();
  final _messageReadController = StreamController<String>.broadcast();

  // Streams pour les appels WebRTC
  final _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callOfferController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Dernière offre SDP reçue (permet de la récupérer si elle arrive
  // avant que la page d'appel ne soit prête à l'écouter)
  Map<String, dynamic>? _pendingCallOffer;
  Map<String, dynamic>? get pendingCallOffer => _pendingCallOffer;
  void clearPendingCallOffer() {
    _pendingCallOffer = null;
  }

  final _callAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters pour les streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onRoomJoined => _roomJoinedController.stream;
  Stream<String> get onMessageRead => _messageReadController.stream;

  // Getters pour les streams d'appels
  Stream<Map<String, dynamic>> get onIncomingCall =>
      _incomingCallController.stream;
  Stream<Map<String, dynamic>> get onCallOffer => _callOfferController.stream;
  Stream<Map<String, dynamic>> get onCallAnswer => _callAnswerController.stream;
  Stream<Map<String, dynamic>> get onCallAccepted =>
      _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get onIceCandidate =>
      _iceCandidateController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;
  bool get isWebRTCConnected => _webrtcSocket?.connected ?? false;

  // Connexion avec token JWT (pour les messages)
  Future<void> connect(String accessToken) async {
    if (_socket?.connected ?? false) {
      await disconnect();
    }

    _socket = socket_io.io(
      baseUrl,
      socket_io.OptionBuilder().setTransports(['websocket']).setAuth({
        'token': accessToken,
      }).build(),
    );

    _socket!.onConnect((_) {
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _connectionController.add(false);
    });

    _socket!.on('joinedRoom', (data) {
      _roomJoinedController.add(data['roomId']);
    });

    _socket!.on('newMessage', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messageRead', (data) {
      _messageReadController.add(data['messageId']);
    });

    _socket!.on('error', (data) {
      _errorController.add(data['message']);
    });
  }

  // Connexion WebRTC (pour les appels audio/vidéo)
  Future<void> connectWebRTC(String accessToken) async {
    try {
      debugPrint('[WebSocket] Début connexion WebRTC, URL: $baseUrl/webrtc');
      debugPrint(
        '[WebSocket] Token JWT (premiers 20 chars): ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...',
      );

      // Si déjà connecté, ne pas se reconnecter
      if (_webrtcSocket?.connected ?? false) {
        debugPrint(
          '[WebSocket] WebSocket WebRTC déjà connecté, pas de reconnexion nécessaire',
        );
        return;
      }

      final completer = Completer<void>();

      _webrtcSocket = socket_io.io(
        '$baseUrl/webrtc',
        socket_io.OptionBuilder().setTransports(['websocket']).setAuth({
          'token': accessToken,
        }).build(),
      );

      debugPrint('[WebSocket] Socket.io instance créée');

      _webrtcSocket!.onConnect((_) {
        debugPrint('[WebSocket] WebRTC connecté avec succès');
        debugPrint('[WebSocket] Socket ID: ${_webrtcSocket!.id}');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _webrtcSocket!.onDisconnect((_) {
        final transportName =
            _webrtcSocket?.io.engine?.transport?.name ?? 'unknown';
        debugPrint('[WebSocket] WebRTC déconnecté, raison: $transportName');
        // Ne pas marquer le completer comme erreur pour permettre les reconnexions futures
        if (!completer.isCompleted) {
          debugPrint(
            '[WebSocket] Connexion initiale terminée (déconnecté après connexion)',
          );
          completer.complete();
        }
      });

      _webrtcSocket!.onConnectError((data) {
        debugPrint('[WebSocket] ERREUR connexion WebRTC: $data');
        debugPrint('[WebSocket] Détails erreur: ${data.toString()}');
        final errorMessage = 'Erreur de connexion WebRTC: $data';
        _errorController.add(errorMessage);
        if (!completer.isCompleted) {
          completer.completeError(errorMessage);
        }
      });

      _webrtcSocket!.onError((data) {
        debugPrint('[WebSocket] ERREUR WebRTC: $data');
      });

      // Événements WebRTC pour les appels
      _webrtcSocket!.on('incomingCall', (data) {
        debugPrint('[WebSocket] incomingCall reçu: $data');
        _incomingCallController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('callAccepted', (data) {
        debugPrint('[WebSocket] callAccepted reçu: $data');
        _callAcceptedController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('callRejected', (data) {
        debugPrint('[WebSocket] callRejected reçu: $data');
        _errorController.add('Call rejected by the other party');
      });

      _webrtcSocket!.on('callOffer', (data) {
        debugPrint('[WebSocket] callOffer reçu: $data');
        _pendingCallOffer = Map<String, dynamic>.from(data);
        _callOfferController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('callAnswer', (data) {
        debugPrint('[WebSocket] callAnswer reçu: $data');
        _callAnswerController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('iceCandidate', (data) {
        debugPrint(
          '[WebSocket] iceCandidate reçu pour ${data['targetUserId']}',
        );
        _iceCandidateController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('callEnded', (data) {
        debugPrint('[WebSocket] callEnded reçu: $data');
        _callEndedController.add(Map<String, dynamic>.from(data));
      });

      _webrtcSocket!.on('error', (data) {
        debugPrint('[WebSocket] ERREUR événement WebRTC: $data');
        debugPrint('[WebSocket] Type d\'erreur: ${data.runtimeType}');
        _errorController.add(data['message'] ?? data.toString());
      });

      // Attendre que la connexion soit effective
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[WebSocket] Timeout connexion WebRTC');
          throw Exception('Timeout de connexion WebRTC');
        },
      );
    } catch (e) {
      debugPrint('[WebSocket] ERREUR connectWebRTC: $e');
      rethrow;
    }
  }

  // Rejoindre une room
  void joinRoom(String roomId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('WebSocket non connecté');
    }
    _socket!.emit('joinRoom', {'roomId': roomId});
  }

  // Envoyer un message texte
  void sendMessage({required String roomId, required String content}) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('WebSocket non connecté');
    }
    _socket!.emit('sendMessage', {
      'roomId': roomId,
      'type': 'text',
      'content': content,
    });
  }

  // Envoyer un message audio
  void sendAudioMessage({
    required String roomId,
    required String audioUrl,
    required int audioDuration,
  }) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('WebSocket non connecté');
    }
    _socket!.emit('sendMessage', {
      'roomId': roomId,
      'type': 'audio',
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
    });
  }

  // Marquer un message comme lu
  void markAsRead(String messageId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('WebSocket non connecté');
    }
    _socket!.emit('markAsRead', {'messageId': messageId});
  }

  // ===== Méthodes WebRTC pour les appels =====

  // Initier un appel
  void initiateCall({
    required String targetUserId,
    required String targetUserRole,
    required String teleconsultationId,
    required String callType, // 'audio' ou 'video'
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('initiateCall', {
      'targetUserId': targetUserId,
      'targetUserRole': targetUserRole,
      'teleconsultationId': teleconsultationId,
      'callType': callType,
    });
  }

  // Envoyer une offre SDP
  void sendCallOffer({
    required String targetUserId,
    required String sdp,
    required String type,
    String? callType,
    bool isRenegotiation = false,
  }) {
    debugPrint(
      '[WebSocket] sendCallOffer appelé, connecté: ${_webrtcSocket?.connected}',
    );
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      debugPrint(
        '[WebSocket] ERREUR: WebSocket non connecté lors de sendCallOffer',
      );
      throw Exception('WebRTC WebSocket non connecté');
    }
    debugPrint('[WebSocket] Envoi de callOffer à $targetUserId');
    _webrtcSocket!.emit('callOffer', {
      'targetUserId': targetUserId,
      'sdp': sdp,
      'type': type,
      'callType': ?callType,
      'isRenegotiation': isRenegotiation,
    });
    debugPrint('[WebSocket] callOffer envoyé avec succès');
  }

  // Envoyer une réponse SDP
  void sendCallAnswer({
    required String targetUserId,
    required String sdp,
    required String type,
    String? callType,
    bool isRenegotiation = false,
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('callAnswer', {
      'targetUserId': targetUserId,
      'sdp': sdp,
      'type': type,
      'callType': ?callType,
      'isRenegotiation': isRenegotiation,
    });
  }

  // Envoyer un candidat ICE
  void sendIceCandidate({
    required String targetUserId,
    required String candidate,
    required String sdpMid,
    required int sdpMLineIndex,
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('iceCandidate', {
      'targetUserId': targetUserId,
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  // Accepter un appel
  void acceptCall({
    required String callerId,
    required String teleconsultationId,
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('acceptCall', {
      'callerId': callerId,
      'teleconsultationId': teleconsultationId,
    });
  }

  // Refuser un appel
  void rejectCall({
    required String callerId,
    required String teleconsultationId,
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('rejectCall', {
      'callerId': callerId,
      'teleconsultationId': teleconsultationId,
    });
  }

  // Terminer un appel
  void endCall({
    required String targetUserId,
    required String teleconsultationId,
  }) {
    if (_webrtcSocket == null || !_webrtcSocket!.connected) {
      throw Exception('WebRTC WebSocket non connecté');
    }
    _webrtcSocket!.emit('endCall', {
      'targetUserId': targetUserId,
      'teleconsultationId': teleconsultationId,
    });
  }

  // Déconnexion WebRTC
  Future<void> disconnectWebRTC() async {
    if (_webrtcSocket != null) {
      _webrtcSocket!.disconnect();
      _webrtcSocket = null;
    }
  }

  // Déconnexion
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    await disconnectWebRTC();
    await _connectionController.close();
    await _messageController.close();
    await _errorController.close();
    await _roomJoinedController.close();
    await _messageReadController.close();
    await _incomingCallController.close();
    await _callOfferController.close();
    await _callAnswerController.close();
    await _iceCandidateController.close();
    await _callEndedController.close();
  }

  // Dispose pour nettoyer les ressources
  void dispose() {
    disconnect();
  }
}
