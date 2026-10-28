import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? _socket;
  String? _accessToken;

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

  // Getters pour les streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onRoomJoined => _roomJoinedController.stream;
  Stream<String> get onMessageRead => _messageReadController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Connexion avec token JWT
  Future<void> connect(String accessToken) async {
    if (_socket?.connected ?? false) {
      await disconnect();
    }

    _accessToken = accessToken;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder().setTransports(['websocket']).setAuth({
        'token': accessToken,
      }).build(),
    );

    _socket!.onConnect((_) {
      print('WebSocket connecté');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      print('WebSocket déconnecté');
      _connectionController.add(false);
    });

    _socket!.on('joinedRoom', (data) {
      print('Room rejointe: ${data['roomId']}');
      _roomJoinedController.add(data['roomId']);
    });

    _socket!.on('newMessage', (data) {
      print('Nouveau message reçu: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messageRead', (data) {
      print('Message lu: ${data['messageId']}');
      _messageReadController.add(data['messageId']);
    });

    _socket!.on('error', (data) {
      print('Erreur WebSocket: ${data['message']}');
      _errorController.add(data['message']);
    });
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

  // Déconnexion
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _accessToken = null;
    }
    await _connectionController.close();
    await _messageController.close();
    await _errorController.close();
    await _roomJoinedController.close();
    await _messageReadController.close();
  }

  // Dispose pour nettoyer les ressources
  void dispose() {
    disconnect();
  }
}
