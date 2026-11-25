import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère le déverrouillage biométrique (empreinte/Face ID) de l'app.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _enabledKey = 'biometric_lock_enabled';
  static const String _emailKey = 'biometric_login_email';
  static const String _passwordKey = 'biometric_login_password';

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

  // ------------------------------------------------------------------
  // Connexion par biométrie : identifiants stockés de façon sécurisée
  // (Keychain iOS / Keystore Android), jamais en clair.
  // ------------------------------------------------------------------

  /// Sauvegarde email + mot de passe pour la prochaine connexion biométrique.
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordKey, value: password);
    } catch (e) {
      debugPrint('[Biometric] Erreur sauvegarde identifiants: $e');
    }
  }

  /// Retourne les identifiants enregistrés, ou null si absents/incomplets.
  static Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      if (email != null && email.isNotEmpty && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('[Biometric] Erreur lecture identifiants: $e');
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
    } catch (e) {
      debugPrint('[Biometric] Erreur suppression identifiants: $e');
    }
  }

  /// True si la connexion par empreinte est possible : option activée,
  /// capteur disponible et identifiants enregistrés.
  static Future<bool> canBiometricLogin() async {
    if (!await isEnabled()) return false;
    if (!await isAvailable()) return false;
    return await getCredentials() != null;
  }
}
