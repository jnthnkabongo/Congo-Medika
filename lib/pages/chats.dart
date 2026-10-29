import 'package:flutter/material.dart';
import 'package:frontend/services/websocket_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/messages_service.dart';
import 'package:frontend/services/meet_saas_service.dart';
import 'package:url_launcher/url_launcher.dart';

class Chats extends StatefulWidget {
  final String roomId;
  final String teleconsultationId;
  final String doctorName;
  final String? meetSaaSToken;
  final String? organizationId;

  const Chats({
    super.key,
    required this.roomId,
    required this.teleconsultationId,
    this.doctorName = 'Dr. Jean-Pierre Kabongo',
    this.meetSaaSToken,
    this.organizationId,
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

      print('Token récupéré: ${token.substring(0, 20)}...');
      print('Room ID: ${widget.roomId}');

      setState(() {
        _userRole = user['role'];
      });

      // Connecter au WebSocket
      await _wsService.connect(token);

      // Écouter les événements
      _wsService.onConnectionChanged.listen((connected) {
        print('Statut WebSocket: $connected');
        setState(() {
          _isConnected = connected;
          _isLoading = false;
        });

        // Rejoindre la room seulement quand connecté
        if (connected) {
          _wsService.joinRoom(widget.roomId);
        }
      });

      _wsService.onMessage.listen((message) {
        print('Message reçu: $message');
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      });

      _wsService.onError.listen((error) {
        print('Erreur WebSocket: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      _wsService.onRoomJoined.listen((roomId) async {
        print('Room rejointe: $roomId');
        // Charger l'historique des messages
        try {
          final history = await MessagesService.getMessagesByRoomId(roomId);
          if (mounted) {
            setState(() {
              _messages = history;
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('Erreur lors du chargement de l\'historique: $e');
        }
      });

      // Rejoindre la room sera fait après connexion
      // _wsService.joinRoom(widget.roomId);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e')));
      }
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

    try {
      _wsService.sendMessage(
        roomId: widget.roomId,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur d\'envoi: $e')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF95057B),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Color(0xFF95057B)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                    Text(
                      _isConnected ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () async {
              // Créer une réunion audio Meet SaaS et ouvrir dans le navigateur
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Création de l\'appel audio...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final meeting =
                    await MeetSaaSService.createMeetingForTeleconsultation(
                      widget.teleconsultationId,
                      mode: 'AUDIO',
                    );

                if (mounted) {
                  final meetingId = meeting['meetingId'];
                  if (meetingId != null) {
                    // Récupérer le token Meet SaaS de l'utilisateur
                    final meetSaaSToken = await AuthService.getDonneesUser(
                      'meetSaaSToken',
                    );

                    if (meetSaaSToken != null) {
                      // Construire l'URL Meet SaaS avec le meetingId et le token
                      final meetUrl =
                          'https://stax.verstands.dev/join/$meetingId?token=$meetSaaSToken';

                      print('Attempting to launch URL: $meetUrl');
                      final uri = Uri.parse(meetUrl);

                      try {
                        final canLaunch = await canLaunchUrl(uri);
                        print('canLaunchUrl result: $canLaunch');

                        if (canLaunch) {
                          final launched = await launchUrl(uri);
                          print('launchUrl result: $launched');
                        } else {
                          print('canLaunchUrl returned false');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erreur: Impossible d\'ouvrir le navigateur.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Erreur: Token Meet SaaS non disponible. Veuillez vous reconnecter.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Erreur: Impossible de créer le meeting.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () async {
              // Créer une réunion vidéo Meet SaaS et ouvrir dans le navigateur
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Création de l\'appel vidéo...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final meeting =
                    await MeetSaaSService.createMeetingForTeleconsultation(
                      widget.teleconsultationId,
                      mode: 'VIDEO',
                    );

                if (mounted) {
                  final meetingId = meeting['meetingId'];
                  if (meetingId != null) {
                    // Récupérer le token Meet SaaS de l'utilisateur
                    final meetSaaSToken = await AuthService.getDonneesUser(
                      'meetSaaSToken',
                    );

                    if (meetSaaSToken != null) {
                      // Construire l'URL Meet SaaS avec le meetingId et le token
                      final meetUrl =
                          'https://stax.verstands.dev/join/$meetingId?token=$meetSaaSToken';

                      print('Attempting to launch URL: $meetUrl');
                      final uri = Uri.parse(meetUrl);

                      try {
                        final canLaunch = await canLaunchUrl(uri);
                        print('canLaunchUrl result: $canLaunch');

                        if (canLaunch) {
                          final launched = await launchUrl(uri);
                          print('launchUrl result: $launched');
                        } else {
                          print('canLaunchUrl returned false');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erreur: Impossible d\'ouvrir le navigateur.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Erreur: Token Meet SaaS non disponible. Veuillez vous reconnecter.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Erreur: Impossible de créer le meeting.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
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
                    color: const Color(0xFF95057B),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSent ? const Color(0xFF95057B) : Colors.white,
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
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
