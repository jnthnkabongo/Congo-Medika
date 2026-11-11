import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CallSoundService {
  static final CallSoundService _instance = CallSoundService._internal();
  factory CallSoundService() => _instance;
  CallSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;

  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/ringtone.wav'));
      debugPrint('[CallSoundService] Sonnerie démarrée');
    } catch (e) {
      debugPrint('[CallSoundService] ERREUR lecture sonnerie: $e');
      _isRinging = false;
    }
  }

  Future<void> stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    try {
      await _player.stop();
      debugPrint('[CallSoundService] Sonnerie arrêtée');
    } catch (e) {
      debugPrint('[CallSoundService] ERREUR arrêt sonnerie: $e');
    }
  }
}
