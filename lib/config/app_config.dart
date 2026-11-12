/// Configuration centrale des URLs de l'API.
///
/// - Dev local  : IP du Mac sur le réseau local (téléphones sur le même WiFi)
/// - Production : domaine HTTPS du serveur (ex: https://api.congomedika.com)
///
/// Pour passer en production, ne changer QUE ces deux lignes.
class AppConfig {
  AppConfig._();

  /// URL de base de l'API REST (sans le suffixe /api/...)
  static const String apiBaseUrl = 'http://217.76.58.7:3001';

  /// URL de base du WebSocket WebRTC (sans le suffixe /webrtc)
  /// Socket.IO fonctionne aussi en HTTPS/wss en production.
  static const String wsBaseUrl = apiBaseUrl;
}
