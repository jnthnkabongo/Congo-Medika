import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';

class AppelEnCours extends StatefulWidget {
  final String? meetingId;
  final String? token;
  final String? organizationId;
  final String? targetUserId;
  final String? targetUserRole;
  final String? teleconsultationId;
  final bool isCaller;
  final String callType;

  const AppelEnCours({
    super.key,
    this.meetingId,
    this.token,
    this.organizationId,
    this.targetUserId,
    this.targetUserRole,
    this.teleconsultationId,
    this.isCaller = true,
    this.callType = 'audio',
  });

  @override
  State<AppelEnCours> createState() => _AppelEnCoursState();
}

class _AppelEnCoursState extends State<AppelEnCours> {
  final WebRTCService _webrtcService = WebRTCService();
  final WebSocketService _webSocketService = WebSocketService();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isEndingCall = false;
  int _callDuration = 0;
  String? _targetUserId;
  RTCSessionDescription? _localDescription;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isVideoCall = false;
  bool _isCameraEnabled = false;
  bool _remoteHasVideo = false;
  bool _isRenegotiating = false;
  bool _callEstablished = false;
  bool _isVideoNegotiated = false;

  Timer? _callTimer;

  bool _hasActiveVideo(MediaStream? stream) {
    return stream?.getVideoTracks().any((track) => track.enabled) ?? false;
  }

  bool get _hasLocalVideoTrack =>
      _localStream?.getVideoTracks().isNotEmpty ?? false;

  void _refreshMediaState() {
    _remoteHasVideo = _hasActiveVideo(_remoteStream);
    _isCameraEnabled =
        _localStream?.getVideoTracks().any((track) => track.enabled) ?? false;
    _isVideoCall =
        widget.callType == 'video' || _remoteHasVideo || _isCameraEnabled;
  }

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      debugPrint('[AppelEnCours] Début initialisation de l\'appel');
      debugPrint('[AppelEnCours] isCaller: ${widget.isCaller}');
      debugPrint('[AppelEnCours] targetUserId: ${widget.targetUserId}');
      debugPrint(
        '[AppelEnCours] teleconsultationId: ${widget.teleconsultationId}',
      );

      // Forcer le haut-parleur pour Android
      try {
        await _webrtcService.setSpeakerphoneOn(true);
        debugPrint('[AppelEnCours] Haut-parleur activé');
      } catch (e) {
        debugPrint('[AppelEnCours] Erreur activation haut-parleur: $e');
      }

      // Initialiser les renderers vidéo
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _isVideoCall = widget.callType == 'video';

      // Récupérer le token JWT
      debugPrint('[AppelEnCours] Récupération du token JWT...');
      final accessToken = await AuthService.getToken();
      if (accessToken == null) {
        debugPrint('[AppelEnCours] ERREUR: Token JWT null');
        _showError('Non authentifié');
        return;
      }
      debugPrint('[AppelEnCours] Token JWT récupéré avec succès');
      debugPrint(
        '[AppelEnCours] Token JWT (premiers 50 chars): ${accessToken.substring(0, accessToken.length > 50 ? 50 : accessToken.length)}...',
      );
      debugPrint('[AppelEnCours] Token JWT longueur: ${accessToken.length}');

      // Connecter au WebSocket WebRTC (réutilise la connexion si déjà connectée)
      debugPrint('[AppelEnCours] Connexion au WebSocket WebRTC...');
      if (!_webSocketService.isWebRTCConnected) {
        await _webSocketService.connectWebRTC(accessToken);
        debugPrint('[AppelEnCours] WebSocket WebRTC connecté');
      } else {
        debugPrint(
          '[AppelEnCours] WebSocket WebRTC déjà connecté, réutilisation',
        );
      }

      // Attendre explicitement que le WebSocket soit réellement connecté
      int attempts = 0;
      while (!_webSocketService.isWebRTCConnected && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint(
          '[AppelEnCours] ERREUR: WebSocket non connecté après attente',
        );
        _showError('Erreur de connexion WebSocket');
        return;
      }
      debugPrint(
        '[AppelEnCours] WebSocket confirmé connecté après $attempts tentatives',
      );

      // Vider le buffer des candidats ICE en attente
      _webrtcService.flushIceCandidateBuffer();

      // Écouter le flux local (micro et caméra)
      _webrtcService.onLocalStream.listen((stream) {
        _localStream = stream;
        _localRenderer.srcObject = stream;
        _refreshMediaState();
        if (mounted) setState(() {});
      });

      // Écouter le flux distant
      _webrtcService.onRemoteStream.listen((stream) {
        debugPrint(
          '[AppelEnCours] Stream distant reçu, tracks: ${stream.getTracks().length}',
        );
        stream.getTracks().forEach((track) {
          debugPrint(
            '[AppelEnCours] Track distant: ${track.kind}, enabled: ${track.enabled}, id: ${track.id}',
          );
        });
        _remoteStream = stream;
        _refreshMediaState();
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
        debugPrint('[AppelEnCours] Stream distant assigné au renderer');
      });

      // Écouter les candidats ICE du WebSocket
      _webSocketService.onIceCandidate.listen((data) {
        debugPrint('[AppelEnCours] ICE Candidate reçu du WebSocket');
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        _webrtcService.addCandidate(candidate);
      });

      // Écouter les offres et réponses SDP (appel initial + renégociation vidéo)
      _webSocketService.onCallOffer.listen((data) {
        _handleCallOffer(data);
      });
      _webSocketService.onCallAnswer.listen((data) {
        _handleCallAnswer(data);
      });

      // Écouter la fin de l'appel
      _webSocketService.onCallEnded.listen((_) {
        debugPrint('[AppelEnCours] Appel terminé reçu');
        _endCall();
      });

      _webrtcService.onCallState.listen((state) {
        debugPrint('[AppelEnCours] État de l\'appel: $state');
        if (state == 'disconnected') {
          _endCall();
        }
      });

      // Écouter les erreurs WebSocket
      _webSocketService.onError.listen((error) {
        debugPrint('[AppelEnCours] ERREUR WebSocket: $error');
        _showError('Erreur WebSocket: $error');
      });

      setState(() {
        _targetUserId = widget.targetUserId;
      });

      // Si c'est l'appelant, initier l'appel
      if (widget.isCaller) {
        if (widget.targetUserId != null) {
          debugPrint(
            '[AppelEnCours] Initiation de l\'appel en tant qu\'appelant...',
          );
          _initiateCall();
        } else {
          debugPrint('[AppelEnCours] ERREUR: targetUserId est null');
          _showError('targetUserId est requis pour initier un appel');
        }
      } else if (!widget.isCaller) {
        debugPrint(
          '[AppelEnCours] Attente de l\'offre en tant que receveur...',
        );
        // Initialiser la PeerConnection pour le receveur
        await _webrtcService.initializePeerConnection(
          targetUserId: widget.targetUserId,
        );
        // Mettre à jour le targetUserId dans WebRTCService pour envoyer les candidats ICE
        if (widget.targetUserId != null) {
          _webrtcService.updateTargetUserId(widget.targetUserId!);
        }
        // Attendre l'offre
        _waitForCallOffer();
      }

      _startCallTimer();
      debugPrint('[AppelEnCours] Initialisation terminée avec succès');
    } catch (e, stackTrace) {
      debugPrint('[AppelEnCours] ERREUR lors de l\'initialisation: $e');
      debugPrint('[AppelEnCours] Stack trace: $stackTrace');
      _showError('Erreur lors de l\'initialisation de l\'appel: $e');
    }
  }

  Future<void> _initiateCall() async {
    try {
      debugPrint('[AppelEnCours] Début initiation de l\'appel');
      debugPrint('[AppelEnCours] targetUserId: ${widget.targetUserId}');
      debugPrint('[AppelEnCours] targetUserRole: ${widget.targetUserRole}');
      debugPrint(
        '[AppelEnCours] teleconsultationId: ${widget.teleconsultationId}',
      );

      // Attendre que le WebSocket soit connecté avant de continuer
      debugPrint(
        '[AppelEnCours] Vérification connexion WebSocket... État actuel: ${_webSocketService.isWebRTCConnected}',
      );
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint('[AppelEnCours] WebSocket non connecté, attente...');
        // Attendre jusqu'à 10 secondes que le WebSocket se connecte
        int attempts = 0;
        while (!_webSocketService.isWebRTCConnected && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
          if (attempts % 10 == 0) {
            debugPrint(
              '[AppelEnCours] En attente WebSocket... ($attempts/100)',
            );
          }
        }
        if (!_webSocketService.isWebRTCConnected) {
          debugPrint(
            '[AppelEnCours] ERREUR: WebSocket toujours non connecté après 10 secondes',
          );
          _showError('Erreur de connexion WebSocket');
          return;
        }
        debugPrint(
          '[AppelEnCours] WebSocket connecté après $attempts tentatives',
        );
      } else {
        debugPrint('[AppelEnCours] WebSocket déjà connecté');
      }

      // Vérification finale avant de continuer
      debugPrint(
        '[AppelEnCours] Vérification finale WebSocket: ${_webSocketService.isWebRTCConnected}',
      );
      if (!_webSocketService.isWebRTCConnected) {
        debugPrint(
          '[AppelEnCours] ERREUR: WebSocket déconnecté avant initialisation',
        );
        _showError('Erreur de connexion WebSocket');
        return;
      }

      // Envoyer les candidats ICE qui pourraient être en attente dans le buffer
      _webrtcService.flushIceCandidateBuffer();

      // Initialiser la PeerConnection AVANT de créer l'offre
      // Cela permet de configurer l'écouteur ICE avec le bon targetUserId
      debugPrint('[AppelEnCours] Initialisation de la PeerConnection...');
      await _webrtcService.initializePeerConnection(
        targetUserId: widget.targetUserId,
      );
      debugPrint(
        '[AppelEnCours] PeerConnection initialisée avec targetUserId: ${widget.targetUserId}',
      );

      // Petit délai pour s'assurer que l'écouteur ICE est prêt
      await Future.delayed(const Duration(milliseconds: 200));

      // Envoyer la notification d'appel
      debugPrint('[AppelEnCours] Envoi de la notification d\'appel...');
      _webSocketService.initiateCall(
        targetUserId: widget.targetUserId!,
        targetUserRole: widget.targetUserRole ?? 'doctor',
        teleconsultationId: widget.teleconsultationId ?? '',
        callType: widget.callType,
      );
      debugPrint('[AppelEnCours] Notification d\'appel envoyée');

      // Créer l'offre SDP (la PeerConnection est déjà initialisée)
      debugPrint('[AppelEnCours] Création de l\'offre SDP...');
      final offer = await _webrtcService.createOffer(
        audio: true,
        video: widget.callType == 'video',
        targetUserId: widget.targetUserId,
      );
      debugPrint('[AppelEnCours] Offre SDP créée: ${offer.type}');

      // Sauvegarder l'offre locale
      _localDescription = offer;
      if (widget.callType == 'video') {
        _isVideoNegotiated = true;
      }

      // Écouter callAccepted pour envoyer l'offre au médecin
      _webSocketService.onCallAccepted.listen((data) async {
        debugPrint('[AppelEnCours] Appel accepté reçu: $data');

        // Envoyer l'offre au médecin
        if (widget.targetUserId != null && _localDescription != null) {
          _webSocketService.sendCallOffer(
            targetUserId: widget.targetUserId!,
            sdp: _localDescription!.sdp!,
            type: _localDescription!.type!,
            callType: widget.callType,
          );
          debugPrint('[AppelEnCours] Offre envoyée au médecin');

          // Attendre un peu que le WebSocket soit bien connecté, puis vider le buffer
          await Future.delayed(const Duration(milliseconds: 200));
          _webrtcService.flushIceCandidateBuffer();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[AppelEnCours] ERREUR lors de l\'initiation: $e');
      debugPrint('[AppelEnCours] Stack trace: $stackTrace');
      _showError('Erreur lors de l\'initiation de l\'appel: $e');
    }
  }

  // SDP déjà traitées (évite de traiter deux fois la même offre)
  final Set<String> _handledOfferSdps = {};

  Future<void> _waitForCallOffer() async {
    debugPrint('[AppelEnCours] En attente de l\'offre d\'appel...');

    // L'offre a pu arriver avant que cette page ne soit montée
    // (le patient l'envoie dès réception de callAccepted).
    // La traiter depuis le buffer si elle est en attente.
    final pendingOffer = _webSocketService.pendingCallOffer;
    if (pendingOffer != null &&
        pendingOffer['callerId'].toString() == widget.targetUserId &&
        !_handledOfferSdps.contains(pendingOffer['sdp'])) {
      debugPrint(
        '[AppelEnCours] Offre SDP trouvée dans le buffer, traitement...',
      );
      await _handleCallOffer(pendingOffer);
    }
  }

  Future<void> _handleCallOffer(Map<String, dynamic> data) async {
    // Marquer la SDP comme traitée dès le début pour éviter les doublons
    final sdp = data['sdp'];
    if (sdp != null && !_handledOfferSdps.add(sdp)) {
      debugPrint('[AppelEnCours] Offre SDP déjà traitée, ignorée');
      return;
    }

    try {
      if (data['sdp'] == null || data['type'] == null) {
        debugPrint('[AppelEnCours] ERREUR: Offre invalide - sdp ou type null');
        return;
      }

      final callerId = data['callerId']?.toString();
      if (callerId == null) {
        debugPrint('[AppelEnCours] ERREUR: callerId manquant dans l\'offre');
        return;
      }

      final sdpText = data['sdp'] as String? ?? '';
      final offerHasVideo =
          data['callType'] == 'video' || sdpText.contains('m=video');
      final isRenegotiation =
          data['isRenegotiation'] == true || _callEstablished;

      debugPrint('[AppelEnCours] Offre d\'appel reçue: $data');
      final offer = RTCSessionDescription(data['sdp'], data['type']);
      await _webrtcService.setRemoteDescription(offer);
      _webrtcService.updateTargetUserId(callerId);

      var answerVideo = offerHasVideo;
      if (isRenegotiation && offerHasVideo && !_webrtcService.hasLocalVideo) {
        try {
          await _webrtcService.enableVideo();
        } catch (e) {
          debugPrint('[AppelEnCours] Impossible d\'activer la caméra: $e');
          answerVideo = false;
        }
      }

      debugPrint('[AppelEnCours] Création de la réponse...');
      final answer = await _webrtcService.createAnswer(
        audio: true,
        video: answerVideo,
        targetUserId: callerId,
      );

      _webSocketService.sendCallAnswer(
        targetUserId: callerId,
        sdp: answer.sdp!,
        type: answer.type!,
        callType: answerVideo ? 'video' : 'audio',
        isRenegotiation: isRenegotiation,
      );

      _callEstablished = true;
      _isVideoNegotiated = answerVideo;
      _targetUserId = callerId;
      _refreshMediaState();
      if (mounted) setState(() {});

      // L'offre a été consommée, la retirer du buffer
      if (_webSocketService.pendingCallOffer?['sdp'] == sdp) {
        _webSocketService.clearPendingCallOffer();
      }
    } catch (e, stackTrace) {
      debugPrint('[AppelEnCours] ERREUR lors de la réception de l\'offre: $e');
      debugPrint('[AppelEnCours] Stack trace: $stackTrace');
      _showError('Erreur lors de la réception de l\'offre: $e');
    }
  }

  Future<void> _handleCallAnswer(Map<String, dynamic> data) async {
    try {
      if (data['sdp'] == null || data['type'] == null) {
        debugPrint(
          '[AppelEnCours] ERREUR: Réponse invalide - sdp ou type null',
        );
        return;
      }

      final answer = RTCSessionDescription(data['sdp'], data['type']);
      await _webrtcService.setRemoteDescription(answer);

      final isRenegotiation =
          data['isRenegotiation'] == true || _isRenegotiating;
      if (isRenegotiation) {
        _isRenegotiating = false;
      }

      _callEstablished = true;
      final answerHasVideo =
          data['callType'] == 'video' ||
          (data['sdp'] as String? ?? '').contains('m=video');
      if (answerHasVideo) {
        _isVideoNegotiated = true;
        _isVideoCall = true;
      }
      _refreshMediaState();
      _webrtcService.flushIceCandidateBuffer();
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('[AppelEnCours] ERREUR lors de la réponse d\'appel: $e');
      debugPrint('[AppelEnCours] Stack trace: $stackTrace');
      _isRenegotiating = false;
      _showError('Erreur lors de la réponse d\'appel: $e');
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() async {
    await _webrtcService.muteAudio(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleSpeaker() async {
    await _webrtcService.setSpeakerphoneOn(!_isSpeakerOn);
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  Future<void> _toggleVideo() async {
    if (_targetUserId == null || _isRenegotiating) return;

    if (!_webrtcService.hasLocalVideo || !_isVideoNegotiated) {
      setState(() {
        _isRenegotiating = true;
      });
      try {
        await _webrtcService.enableVideo();
        final offer = await _webrtcService.createRenegotiationOffer();
        _webSocketService.sendCallOffer(
          targetUserId: _targetUserId!,
          sdp: offer.sdp!,
          type: offer.type!,
          callType: 'video',
          isRenegotiation: true,
        );
        _refreshMediaState();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('[AppelEnCours] ERREUR activation vidéo: $e');
        _showError('Impossible d\'activer la caméra: $e');
        _isRenegotiating = false;
        if (mounted) setState(() {});
      }
      return;
    }

    await _webrtcService.setVideoEnabled(!_isCameraEnabled);
    _refreshMediaState();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    await _webrtcService.switchCamera();
  }

  void _endCall() async {
    // Éviter les appels multiples (callEnded peut être reçu plusieurs fois)
    if (_isEndingCall) return;
    _isEndingCall = true;
    _callTimer?.cancel();

    // Essayer d'envoyer le signal de fin d'appel seulement si connecté
    if (_targetUserId != null && _webSocketService.isWebRTCConnected) {
      try {
        _webSocketService.endCall(
          targetUserId: _targetUserId!,
          teleconsultationId: widget.teleconsultationId ?? '',
        );
      } catch (e) {
        // Ignorer l'erreur si le WebSocket n'est pas connecté
      }
    }

    // Ne PAS déconnecter le WebSocket pour permettre les prochains appels
    // Le WebSocket doit rester connecté pour recevoir les appels entrants
    await _webrtcService.dispose();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _webrtcService.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    // Ne pas déconnecter le WebSocket ici pour éviter les déconnexions automatiques
    // Le WebSocket doit rester connecté pendant que l'utilisateur navigue
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isVideoCall ? _buildVideoCall() : _buildAudioCall();
  }

  Widget _buildAudioCall() {
    return Scaffold(
      backgroundColor: const Color(0xFF8D3188),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Appel en cours',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF8D3188),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Dr. Jean-Pierre Kabongo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_callDuration),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Désactivé' : 'Micro',
                        color: _isMuted ? Colors.red : Colors.blue,
                        onPressed: _toggleMute,
                      ),
                      _buildCallButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        label: _isSpeakerOn ? 'Haut-parleur' : 'Silencieux',
                        color: _isSpeakerOn ? Colors.blue : Colors.grey,
                        onPressed: _toggleSpeaker,
                      ),
                      _buildCallButton(
                        icon: Icons.videocam,
                        label: 'Vidéo',
                        color: Colors.blue,
                        onPressed: _toggleVideo,
                      ),
                      _buildCallButton(
                        icon: Icons.call_end,
                        label: 'Raccrocher',
                        color: Colors.red,
                        onPressed: _endCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // RTCVideoView invisible mais dans l'arbre de widgets pour s'assurer que l'audio est joué
            if (_remoteStream != null)
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: RTCVideoView(_remoteRenderer),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCall() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _remoteHasVideo
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : _buildVideoPlaceholder(),
          ),
          if (_hasLocalVideoTrack)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                    if (!_isCameraEnabled)
                      const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white70,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isRenegotiating)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Activation de la vidéo...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Appel en cours',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Désactivé' : 'Micro',
                      color: _isMuted ? Colors.red : Colors.blue,
                      onPressed: _toggleMute,
                    ),
                    _buildCallButton(
                      icon: _isCameraEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      label: _isCameraEnabled ? 'Caméra ON' : 'Caméra OFF',
                      color: _isCameraEnabled ? Colors.blue : Colors.grey,
                      onPressed: _toggleVideo,
                    ),
                    _buildCallButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Retourner',
                      color: Colors.blue,
                      onPressed: _switchCamera,
                    ),
                    _buildCallButton(
                      icon: Icons.call_end,
                      label: 'Raccrocher',
                      color: Colors.red,
                      onPressed: _endCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: const Color(0xFF8D3188),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF8D3188),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dr. Jean-Pierre Kabongo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_callDuration),
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
