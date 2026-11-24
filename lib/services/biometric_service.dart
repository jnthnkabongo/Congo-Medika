import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère le déverrouillage biométrique (empreinte/Face ID) de l'app.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _enabledKey = 'biometric_lock_enabled';

  /// Préférence utilisateur : le verrouillage est activé ou non.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// True si l'appareil possède un capteur biométrique ou un verrouillage
  /// écran (PIN/motif) utilisable par local_auth.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck || supported;
    } catch (e) {
      debugPrint('[Biometric] Erreur vérification disponibilité: $e');
      return false;
    }
  }

  /// Demande l'authentification biométrique. Retourne true si réussie.
  static Future<bool> authenticate({
    String reason = 'Déverrouillez CongoMedika',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('[Biometric] Authentification échouée: $e');
      return false;
    } catch (e) {
      debugPrint('[Biometric] Authentification échouée: $e');
      return false;
    }
  }
}
