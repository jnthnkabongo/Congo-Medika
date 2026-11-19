import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Route l'audio de l'appel vers le bon périphérique sur Android :
/// casque Bluetooth > casque filaire > haut-parleur/oreillette.
///
/// Sur les autres plateformes (iOS/macOS/web), le système gère déjà le
/// routage via AVAudioSession — ces méthodes sont des no-ops qui
/// renvoient la valeur demandée.
class AudioRouteService {
  AudioRouteService._();

  static const MethodChannel _method = MethodChannel('congomedika/audio');
  static const EventChannel _events = EventChannel(
    'congomedika/audio_events',
  );

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  /// Préférence haut-parleur choisie explicitement par l'utilisateur.
  /// Utilisée pour restaurer la route quand un casque est débranché.
  static bool _userSpeakerPref = false;
  static bool _callActive = false;
  static StreamSubscription<dynamic>? _eventSub;

  /// À appeler une fois au démarrage de l'app (main.dart) ou avant le
  /// premier appel. Écoute les branchements/débranchements de casque
  /// et bascule automatiquement la route pendant un appel.
  static void ensureInitialized() {
    if (!_isAndroid || _eventSub != null) return;
    _eventSub = _events.receiveBroadcastStream().listen((_) async {
      if (!_callActive) return;
      final hasExternal = await hasExternalAudioDevice();
      // Casque branché -> audio dans le casque ; débranché -> on
      // restaure la préférence haut-parleur de l'utilisateur.
      await _applyRoute(speakerOn: hasExternal ? false : _userSpeakerPref);
    });
  }

  /// Indique si un appel WebRTC est en cours (route auto autorisée).
  static void setCallActive(bool active) => _callActive = active;

  /// True si un casque filaire ou Bluetooth est connecté.
  static Future<bool> hasExternalAudioDevice() async {
    if (!_isAndroid) return false;
    try {
      return await _method.invokeMethod<bool>('isHeadsetConnected') ??
          false;
    } catch (e) {
      debugPrint('[AudioRoute] Erreur détection casque: $e');
      return false;
    }
  }

  /// Demande une route audio. Retourne true si le haut-parleur est
  /// réellement actif après application.
  static Future<bool> setAudioRoute({required bool speakerOn}) async {
    _userSpeakerPref = speakerOn;
    return _applyRoute(speakerOn: speakerOn);
  }

  /// Ré-applique une route sans toucher la préférence utilisateur
  /// (utilisé par le listener de branchement de casque).
  static Future<bool> _applyRoute({required bool speakerOn}) async {
    if (!_isAndroid) return speakerOn;
    try {
      return await _method.invokeMethod<bool>('setAudioRoute', {
            'speaker': speakerOn,
          }) ??
          speakerOn;
    } catch (e) {
      debugPrint('[AudioRoute] Erreur routage audio: $e');
      return speakerOn;
    }
  }

  /// Remet le routage par défaut après la fin d'un appel.
  static Future<void> resetAudioRoute() async {
    _callActive = false;
    if (!_isAndroid) return;
    try {
      await _method.invokeMethod('resetAudioRoute');
    } catch (_) {}
  }
}
