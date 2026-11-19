import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/websocket_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/messages_service.dart';
import 'appel_en_cours.dart';
import '../theme/app_theme.dart';

class Chats extends StatefulWidget {
  final String roomId;
  final String teleconsultationId;
  final String doctorName;
  final String? meetSaaSToken;
  final String? organizationId;
  final int? doctorId;
  final int? patientId;

  const Chats({
    super.key,
    required this.roomId,
    required this.teleconsultationId,
    this.doctorName = 'Dr. Jean-Pierre Kabongo',
    this.meetSaaSToken,
    this.organizationId,
    this.doctorId,
    this.patientId,
  });

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  final TextEditingController _messageController = TextEditingController();
  final WebSocketService _wsService = WebSocketService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isLoading = true;
  String? _userRole;

  // Abonnements aux streams du WebSocketService (singleton) —
  // doivent être annulés dans dispose() pour éviter les setState
  // sur un State détruit.
  final List<StreamSubscription> _subscriptions = [];

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      // Récupérer le token stocké
      final token = await AuthService.getToken();
      final user = await AuthService.getDonneesUser(AuthService.userKey);

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez vous connecter d\'abord'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _userRole = user['role'];
      });

      // Annuler les anciens listeners (ex: bouton "Reconnecter")
      // avant de réécouter, sinon on dupliquerait les abonnements.
      _cancelSubscriptions();

      // Écouter les événements AVANT de connecter/rejoindre :
      // sinon onRoomJoined (chargement de l'historique) et
      // onConnectionChanged peuvent être émis avant l'abonnement.
      _subscriptions.add(
        _wsService.onConnectionChanged.listen((connected) {
          if (!mounted) return;
          setState(() {
            _isConnected = connected;
            _isLoading = false;
          });

          // Rejoindre la room seulement quand connecté
          if (connected) {
            _wsService.joinRoom(widget.roomId);
          }
        }),
      );

      _subscriptions.add(
        _wsService.onMessage.listen((message) {
          if (!mounted) return;
          setState(() {
            // Si un message optimiste identique existe (ajouté à
            // l'envoi), on le remplace par la version serveur au lieu
            // d'ajouter un doublon.
            final pendingIndex = _messages.indexWhere(
              (m) =>
                  m['_pending'] == true &&
                  m['content'] == message['content'] &&
                  m['senderType'] == message['senderType'],
            );
            if (pendingIndex >= 0) {
              _messages[pendingIndex] = message;
            } else {
              _messages.add(message);
            }
          });
          _scrollToBottom();
        }),
      );

      _subscriptions.add(
        _wsService.onError.listen((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }),
      );

      _subscriptions.add(
        _wsService.onRoomJoined.listen((roomId) async {
          // Charger l'historique des messages
          try {
            final history = await MessagesService.getMessagesByRoomId(roomId);
            if (mounted) {
              setState(() {
                // Fusionner au lieu d'écraser : l'historique fait foi
                // pour les ids connus, mais on conserve les messages
                // optimistes (_pending) et tout message reçu pendant
                // le chargement qui ne serait pas encore en base.
                final merged = <String, Map<String, dynamic>>{};
                for (final m in _messages) {
                  final id = m['id']?.toString();
                  if (id != null) merged[id] = m;
                }
                for (final h in history) {
                  merged[h['id']?.toString() ?? h['uuid'].toString()] = h;
                }
                _messages = [
                  ...merged.values,
                  ..._messages.where((m) => m['_pending'] == true),
                ]..sort((a, b) {
                    final ta = DateTime.tryParse(
                      a['createdAt']?.toString() ?? '',
                    );
                    final tb = DateTime.tryParse(
                      b['createdAt']?.toString() ?? '',
                    );
                    if (ta == null || tb == null) return 0;
                    return ta.compareTo(tb);
                  });
              });
              _scrollToBottom();
            }
          } catch (e) {
            debugPrint('[Chats] ERREUR chargement historique: $e');
          }
        }),
      );

      // Connecter au WebSocket — sans détruire la connexion existante :
      // connect() reconnecte de zéro si déjà connecté, ce qui couperait
      // brièvement le socket à chaque ouverture de la page.
      if (_wsService.isConnected) {
        // Déjà connecté : l'état est reflété immédiatement
        // (onConnectionChanged n'émet pas "true" si la connexion
        // existait déjà) puis on rejoint la room.
        if (mounted) {
          setState(() {
            _isConnected = true;
            _isLoading = false;
          });
        }
        _wsService.joinRoom(widget.roomId);
      } else {
        await _wsService.connect(token);
        // Si la connexion a réussi entre-temps, onConnectionChanged
        // aura déjà déclenché joinRoom via le listener ci-dessus.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e')));
    }
  }

  /// Recharge l'historique des messages (pull-to-refresh) en fusionnant
  /// avec la liste courante pour ne pas perdre les messages optimistes
  /// ou recus pendant le chargement.
  Future<void> _refreshMessages() async {
    try {
      final history = await MessagesService.getMessagesByRoomId(
        widget.roomId,
      );
      if (!mounted) return;
      setState(() {
        final merged = <String, Map<String, dynamic>>{};
        for (final m in _messages) {
          final id = m['id']?.toString();
          if (id != null) merged[id] = m;
        }
        for (final h in history) {
          merged[h['id']?.toString() ?? h['uuid'].toString()] = h;
        }
        _messages = [
          ...merged.values,
          ..._messages.where((m) => m['_pending'] == true),
        ]..sort((a, b) {
            final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '');
            final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '');
            if (ta == null || tb == null) return 0;
            return ta.compareTo(tb);
          });
      });
    } catch (e) {
      debugPrint('[Chats] ERREUR refresh historique: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebSocket non connecté. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final content = _messageController.text.trim();
    final pendingMsg = <String, dynamic>{
      'id': null,
      'uuid': null,
      'content': content,
      'senderType': _userRole,
      'type': 'text',
      'createdAt': DateTime.now().toIso8601String(),
      '_pending': true,
    };
    try {
      // Ajout optimiste : le message s'affiche immédiatement, même si
      // l'écho newMessage tarde ou si l'émetteur n'est plus dans la
      // room (reconnexion). L'écho serveur le remplacera (dédup
      // dans le listener onMessage).
      if (mounted) {
        setState(() {
          _messages.add(pendingMsg);
        });
        _scrollToBottom();
      }
      _wsService.sendMessage(roomId: widget.roomId, content: content);
      _messageController.clear();
    } catch (e) {
      // Envoi impossible : retirer le message optimiste pour ne pas
      // afficher un message jamais transmis.
      if (mounted) {
        setState(() {
          _messages.remove(pendingMsg);
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur d\'envoi: $e')));
    }
  }

  Future<void> _startCall({required bool video}) async {
    try {
      final user = await AuthService.getDonneesUser('user');
      final currentUserId = user != null
          ? (user['id'] is String ? int.parse(user['id']) : user['id'])
          : null;

      int? targetUserId;
      String targetUserRole;

      if (currentUserId == widget.doctorId) {
        targetUserId = widget.patientId;
        targetUserRole = 'patient';
      } else {
        targetUserId = widget.doctorId;
        targetUserRole = 'doctor';
      }

      if (targetUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de déterminer le destinataire de l\'appel',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppelEnCours(
            teleconsultationId: widget.teleconsultationId,
            targetUserId: targetUserId.toString(),
            targetUserRole: targetUserRole,
            isCaller: true,
            callType: video ? 'video' : 'audio',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _messageController.dispose();
    _scrollController.dispose();
    // NE PAS appeler _wsService.dispose() : c'est un singleton partagé,
    // le détruire casserait le WebSocket pour toute l'application.
    // Le socket reste connecté pour les autres écrans.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: AppTheme.adaptiveToolbarHeight(context),
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo-congo-medika-1.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isConnected ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _startCall(video: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => _startCall(video: true),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!_isConnected)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Connexion perdue'),
                  TextButton(
                    onPressed: _initializeWebSocket,
                    child: const Text('Reconnecter'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/logo-congo-medika-1.webp',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(
                          message['content'] as String? ?? '[Audio]',
                          message['senderType'] == _userRole,
                          _formatTime(message['createdAt']),
                        );
                      },
                      ),
                    ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D3188),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return '';

    DateTime time;
    if (dateTime is String) {
      time = DateTime.parse(dateTime);
    } else if (dateTime is DateTime) {
      time = dateTime;
    } else {
      return '';
    }

    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageBubble(String text, bool isSent, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isSent
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSent ? const Color(0xFF8D3188) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
