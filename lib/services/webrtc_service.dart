import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  MediaStream? _videoStream;
  final WebSocketService _webSocketService = WebSocketService();
  String? _targetUserId;

  final _localStreamController = StreamController<MediaStream>.broadcast();
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _callStateController = StreamController<String>.broadcast();

  // Buffer pour les candidats ICE
  final List<Map<String, dynamic>> _iceCandidateBuffer = [];

  // Buffer pour les candidats ICE distants en attente de la description distante
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _remoteDescriptionSet = false;
  bool _disposed = false;

  Stream<MediaStream> get onLocalStream => _localStreamController.stream;
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;
  Stream<String> get onCallState => _callStateController.stream;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get hasLocalVideo => _localStream?.getVideoTracks().isNotEmpty ?? false;
  bool get hasRemoteVideo =>
      _remoteStream?.getVideoTracks().isNotEmpty ?? false;

  // Configuration STUN (utiliser des serveurs STUN publics)
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // TURN gratuit pour dev/test — à remplacer par un TURN dédié
      // en production (coturn sur un VPS ou service managé type Twilio/Xirsys)
      {
        'urls': [
          'turn:turn.evan-brass.net:3478',
          'turn:turn.evan-brass.net:3478?transport=udp',
          'turn:turn.evan-brass.net:3478?transport=tcp',
          'turn:turn.evan-brass.net:80?transport=tcp',
          'turns:turn.evan-brass.net:443?transport=tcp',
        ],
        'username': 'user',
        'credential': 'password',
      },
    ],
  };

  Future<void> initializePeerConnection({String? targetUserId}) async {
    try {
      debugPrint(
        '[WebRTC] Début initialisation PeerConnection, targetUserId: $targetUserId',
      );
      _targetUserId = targetUserId;
      _remoteDescriptionSet = false;
      _pendingRemoteCandidates.clear();
      final configuration = _iceServers;
      debugPrint('[WebRTC] Configuration ICE: $configuration');

      _peerConnection = await createPeerConnection(configuration);
      debugPrint('[WebRTC] PeerConnection créée avec succès');

      _peerConnection!.onIceCandidate = (candidate) {
        debugPrint('[WebRTC] ICE Candidate reçu: ${candidate.candidate}');
        debugPrint(
          '[WebRTC] targetUserId: $_targetUserId, WebSocket connecté: ${_webSocketService.isWebRTCConnected}',
        );

        if (_targetUserId != null && _webSocketService.isWebRTCConnected) {
          try {
            _webSocketService.sendIceCandidate(
              targetUserId: _targetUserId!,
              candidate: candidate.candidate ?? '',
              sdpMid: candidate.sdpMid ?? '',
              sdpMLineIndex: candidate.sdpMLineIndex ?? 0,
            );
            debugPrint('[WebRTC] ICE Candidate envoyé à $_targetUserId');
          } catch (e) {
            debugPrint('[WebRTC] Erreur envoi ICE Candidate: $e');
          }
        } else {
          // Stocker le candidat dans le buffer
          final candidateData = {
            'candidate': candidate.candidate ?? '',
            'sdpMid': candidate.sdpMid ?? '',
            'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
          };
          _iceCandidateBuffer.add(candidateData);
          debugPrint(
            '[WebRTC] ICE Candidate stocké dans le buffer (${_iceCandidateBuffer.length} candidats en attente)',
          );
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        debugPrint('[WebRTC] ICE Connection State: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          debugPrint('[WebRTC] Connexion ICE déconnectée/échouée');
          _callStateController.add('disconnected');
        } else if (state ==
            RTCIceConnectionState.RTCIceConnectionStateConnected) {
          debugPrint('[WebRTC] Connexion ICE établie');
          _callStateController.add('connected');
        }
      };

      _peerConnection!.onTrack = (event) {
        debugPrint(
          '[WebRTC] Track reçu: ${event.track.kind}, enabled: ${event.track.enabled}',
        );
        // L'audio distant est joué automatiquement par WebRTC.
        // Le stream n'est nécessaire que pour le rendu vidéo.
        if (event.streams.isNotEmpty) {
          // En Unified Plan, audio et vidéo peuvent arriver dans des
          // MediaStream distincts : privilégier celui qui contient une
          // piste vidéo pour que le renderer affiche l'image.
          MediaStream selected = event.streams[0];
          for (final stream in event.streams) {
            if (stream.getVideoTracks().isNotEmpty) {
              selected = stream;
              break;
            }
          }
          _remoteStream = selected;
          debugPrint(
            '[WebRTC] Stream distant reçu (${event.streams.length} streams), tracks: ${_remoteStream!.getTracks().length}, vidéos: ${_remoteStream!.getVideoTracks().length}',
          );
          _remoteStreamController.add(_remoteStream!);
          debugPrint('[WebRTC] Stream distant ajouté au controller');
        } else if (_remoteStream != null) {
          // Nouvelle piste (ex: vidéo) ajoutée au stream distant existant
          // sans nouvel objet stream : on réémet pour rafraîchir l'UI.
          debugPrint(
            '[WebRTC] Track reçu sans stream, réémission du stream existant (${_remoteStream!.getTracks().length} tracks)',
          );
          _remoteStreamController.add(_remoteStream!);
        } else {
          debugPrint('[WebRTC] Track reçu sans stream (audio uniquement)');
        }
      };
    } catch (e) {
      debugPrint(
        '[WebRTC] ERREUR lors de l\'initialisation PeerConnection: $e',
      );
      rethrow;
    }
  }

  Future<MediaStream> getUserMedia({
    bool audio = true,
    bool video = false,
  }) async {
    try {
      debugPrint('[WebRTC] Début getUserMedia, audio: $audio, video: $video');
      final constraints = {
        'audio': audio,
        'video': video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
              }
            : false,
      };
      debugPrint('[WebRTC] Contraintes média: $constraints');

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      debugPrint(
        '[WebRTC] getUserMedia réussi, tracks: ${_localStream!.getTracks().length}',
      );
      _localStream!.getTracks().forEach((track) {
        debugPrint(
          '[WebRTC] Track local: ${track.kind}, enabled: ${track.enabled}, id: ${track.id}',
        );
      });
      _localStreamController.add(_localStream!);
      return _localStream!;
    } catch (e) {
      debugPrint('[WebRTC] ERREUR getUserMedia: $e');
      rethrow;
    }
  }

  Future<void> addLocalTracks() async {
    try {
      debugPrint('[WebRTC] Début addLocalTracks');
      if (_localStream == null || _peerConnection == null) {
        debugPrint(
          '[WebRTC] ERREUR addLocalTracks: localStream ou peerConnection est null',
        );
        return;
      }

      _localStream!.getTracks().forEach((track) {
        debugPrint('[WebRTC] Ajout track: ${track.kind}');
        _peerConnection!.addTrack(track, _localStream!);
      });
      debugPrint('[WebRTC] Tracks locaux ajoutés avec succès');
    } catch (e) {
      debugPrint('[WebRTC] ERREUR addLocalTracks: $e');
      rethrow;
    }
  }

  Future<void> enableVideo() async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection non initialisée');
    }

    if (_localStream == null) {
      await getUserMedia(audio: true, video: true);
      await addLocalTracks();
      return;
    }

    if (hasLocalVideo) {
      await setVideoEnabled(true);
      return;
    }

    final constraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    };

    _videoStream = await navigator.mediaDevices.getUserMedia(constraints);
    final videoTracks = _videoStream?.getVideoTracks() ?? [];
    if (videoTracks.isEmpty) {
      throw StateError('Aucune piste vidéo disponible');
    }
    final videoTrack = videoTracks.first;

    await _localStream!.addTrack(videoTrack);
    await _peerConnection!.addTrack(videoTrack, _localStream!);
    _localStreamController.add(_localStream!);
  }

  Future<void> setVideoEnabled(bool enabled) async {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = enabled;
    }
    _localStreamController.add(_localStream!);
  }

  /// Arrête réellement la caméra : enabled=false ne fait que couper les
  /// frames (la caméra reste ouverte, voyant allumé). Ici on stoppe les
  /// pistes et on les retire du stream local pour pouvoir les recréer
  /// proprement si l'utilisateur repasse en vidéo.
  Future<void> disableVideo() async {
    final local = _localStream;
    if (local == null) return;
    // Copier la liste : getVideoTracks() retourne la liste interne
    // vivante, la modifier pendant l'itération lève
    // ConcurrentModificationError.
    for (final track in List<MediaStreamTrack>.of(local.getVideoTracks())) {
      try {
        await track.stop();
      } catch (e) {
        debugPrint('[WebRTC] Erreur stop piste vidéo: $e');
      }
      try {
        // removeFromNative: false — stop() a déjà libéré la piste côté
        // natif, l'appel removeTrack natif échouerait sinon.
        await local.removeTrack(track, removeFromNative: false);
      } catch (e) {
        debugPrint('[WebRTC] Erreur removeTrack vidéo: $e');
      }
    }
    try {
      await _videoStream?.dispose();
    } catch (_) {}
    _videoStream = null;
    _localStreamController.add(local);
  }

  Future<RTCSessionDescription> createRenegotiationOffer() async {
    if (_peerConnection == null) {
      throw StateError('PeerConnection non initialisée');
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createOffer({
    bool audio = true,
    bool video = false,
    String? targetUserId,
  }) async {
    try {
      debugPrint('[WebRTC] Début createOffer, targetUserId: $targetUserId');

      // Initialiser la PeerConnection seulement si elle n'existe pas déjà
      if (_peerConnection == null) {
        debugPrint('[WebRTC] PeerConnection null, initialisation...');
        await initializePeerConnection(targetUserId: targetUserId);
      } else {
        debugPrint('[WebRTC] PeerConnection existe déjà, réutilisation');
        // Mettre à jour le targetUserId si fourni
        if (targetUserId != null) {
          _targetUserId = targetUserId;
          debugPrint('[WebRTC] targetUserId mis à jour: $targetUserId');
        }
      }

      await getUserMedia(audio: audio, video: video);
      await addLocalTracks();

      debugPrint('[WebRTC] Création de l\'offre SDP');
      final offer = await _peerConnection!.createOffer();
      debugPrint(
        '[WebRTC] Offre créée: ${offer.type}, sdp length: ${offer.sdp?.length}',
      );
      if (offer.sdp != null) {
        debugPrint(
          '[WebRTC] SDP Offer (premiers 500 chars): ${offer.sdp!.substring(0, offer.sdp!.length > 500 ? 500 : offer.sdp!.length)}',
        );
        if (offer.sdp!.contains('opus')) {
          debugPrint('[WebRTC] Codec Opus détecté dans l\'offre');
        }
        if (offer.sdp!.contains('PCMU') || offer.sdp!.contains('PCMA')) {
          debugPrint('[WebRTC] Codec PCMU/PCMA détecté dans l\'offre');
        }
      }

      await _peerConnection!.setLocalDescription(offer);
      debugPrint('[WebRTC] Description locale définie');
      return offer;
    } catch (e) {
      debugPrint('[WebRTC] ERREUR createOffer: $e');
      rethrow;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      debugPrint(
        '[WebRTC] Début setRemoteDescription, type: ${description.type}',
      );
      if (description.sdp != null) {
        debugPrint(
          '[WebRTC] SDP distant (premiers 500 chars): ${description.sdp!.substring(0, description.sdp!.length > 500 ? 500 : description.sdp!.length)}',
        );
        if (description.sdp!.contains('opus')) {
          debugPrint(
            '[WebRTC] Codec Opus détecté dans la description distante',
          );
        }
        if (description.sdp!.contains('PCMU') ||
            description.sdp!.contains('PCMA')) {
          debugPrint(
            '[WebRTC] Codec PCMU/PCMA détecté dans la description distante',
          );
        }
      }
      if (_peerConnection == null) {
        debugPrint('[WebRTC] PeerConnection null, initialisation...');
        await initializePeerConnection();
      }
      await _peerConnection!.setRemoteDescription(description);
      debugPrint('[WebRTC] Description distante définie avec succès');

      // Envoyer les candidats ICE distants reçus en attente
      _remoteDescriptionSet = true;
      if (_pendingRemoteCandidates.isNotEmpty) {
        debugPrint(
          '[WebRTC] Envoi de ${_pendingRemoteCandidates.length} candidats ICE en attente',
        );
        for (final candidate in _pendingRemoteCandidates) {
          try {
            await _peerConnection!.addCandidate(candidate);
          } catch (e) {
            debugPrint('[WebRTC] Erreur ajout candidat ICE en attente: $e');
          }
        }
        _pendingRemoteCandidates.clear();
      }
    } catch (e) {
      debugPrint('[WebRTC] ERREUR setRemoteDescription: $e');
      rethrow;
    }
  }

  void updateTargetUserId(String targetUserId) {
    debugPrint('[WebRTC] Mise à jour targetUserId: $targetUserId');
    _targetUserId = targetUserId;
  }

  // Envoyer les candidats ICE en attente dans le buffer
  void flushIceCandidateBuffer() {
    if (_iceCandidateBuffer.isEmpty) {
      debugPrint('[WebRTC] Buffer ICE vide, rien à envoyer');
      return;
    }

    if (_targetUserId == null || !_webSocketService.isWebRTCConnected) {
      debugPrint(
        '[WebRTC] Impossible d\'envoyer le buffer - targetUserId: $_targetUserId, WebSocket: ${_webSocketService.isWebRTCConnected}',
      );
      return;
    }

    debugPrint(
      '[WebRTC] Envoi de ${_iceCandidateBuffer.length} candidats ICE en attente',
    );

    for (final candidateData in _iceCandidateBuffer) {
      try {
        _webSocketService.sendIceCandidate(
          targetUserId: _targetUserId!,
          candidate: candidateData['candidate'],
          sdpMid: candidateData['sdpMid'],
          sdpMLineIndex: candidateData['sdpMLineIndex'],
        );
        debugPrint('[WebRTC] Candidat ICE envoyé depuis le buffer');
      } catch (e) {
        debugPrint('[WebRTC] Erreur envoi candidat depuis buffer: $e');
      }
    }

    _iceCandidateBuffer.clear();
    debugPrint('[WebRTC] Buffer ICE vidé');
  }

  Future<RTCSessionDescription> createAnswer({
    bool audio = true,
    bool video = false,
    String? targetUserId,
  }) async {
    try {
      debugPrint('[WebRTC] Début createAnswer, targetUserId: $targetUserId');

      // La PeerConnection doit déjà être initialisée avec l'offre reçue
      // Créer le stream local pour permettre au receveur d'envoyer son audio
      if (_localStream == null) {
        debugPrint('[WebRTC] Création du stream local pour le receveur');
        await getUserMedia(audio: audio, video: video);
        await addLocalTracks();
      }

      debugPrint('[WebRTC] Création de la réponse SDP');
      final answer = await _peerConnection!.createAnswer();
      debugPrint(
        '[WebRTC] Réponse créée: ${answer.type}, sdp length: ${answer.sdp?.length}',
      );

      await _peerConnection!.setLocalDescription(answer);
      debugPrint('[WebRTC] Description locale définie');
      return answer;
    } catch (e) {
      debugPrint('[WebRTC] ERREUR createAnswer: $e');
      rethrow;
    }
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    // Les candidats ne peuvent être ajoutés qu'après la description distante.
    // Les stocker en attente évite de les perdre (ils ne sont jamais retransmis).
    if (_peerConnection == null || !_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      debugPrint(
        '[WebRTC] Candidat ICE distant stocké en attente (${_pendingRemoteCandidates.length})',
      );
      return;
    }
    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('[WebRTC] ERREUR addCandidate: $e');
    }
  }

  Future<void> muteAudio(bool mute) async {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !mute;
        debugPrint(
          '[WebRTC] Track audio ${track.id} enabled: ${track.enabled}',
        );
      });
    }
  }

  Future<void> setSpeakerphoneOn(bool enabled) async {
    try {
      await Helper.setSpeakerphoneOn(enabled);
      debugPrint('[WebRTC] Haut-parleur: $enabled');
    } catch (e) {
      debugPrint('[WebRTC] Erreur configuration haut-parleur: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isEmpty) return;
      await Helper.switchCamera(videoTracks.first);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pendingRemoteCandidates.clear();
    _remoteDescriptionSet = false;
    await _videoStream?.dispose();
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    await _localStreamController.close();
    await _remoteStreamController.close();
    await _callStateController.close();
  }
}
