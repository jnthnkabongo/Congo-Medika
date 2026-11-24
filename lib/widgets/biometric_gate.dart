import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

/// Verrouille l'application par biométrie quand l'utilisateur est
/// connecté et a activé l'option dans les paramètres.
/// - Verrou à chaque démarrage de l'app
/// - Re-verrou quand l'app repasse en arrière-plan puis revient
/// - Se déverrouille après une authentification réussie
/// Sans session (login/onboarding) ou option désactivée -> transparent.
class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _enabled = false;
  bool _hasSession = false;
  bool _unlocked = false;
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.sessionEpoch.addListener(_onSessionChanged);
    _evaluate(forceRelock: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.sessionEpoch.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Login ou logout : réévaluer la session et reverrouiller si besoin.
    _evaluate(forceRelock: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Application en arrière-plan -> on reverrouille au retour.
      if (_enabled && _hasSession && mounted) {
        setState(() {
          _unlocked = false;
          _prompted = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _evaluate();
    }
  }

  Future<void> _evaluate({bool forceRelock = false}) async {
    bool enabled;
    String? token;
    try {
      enabled = await BiometricService.isEnabled();
      token = await AuthService.getToken();
    } catch (_) {
      enabled = false;
      token = null;
    }
    if (!mounted) return;

    final hasSession = token != null && token.isNotEmpty;
    setState(() {
      _enabled = enabled;
      _hasSession = hasSession;
      _checking = false;
      if (!enabled || !hasSession) {
        // Pas de verrou nécessaire : on affiche directement le contenu.
        _unlocked = true;
        _prompted = true;
      } else if (forceRelock) {
        _unlocked = false;
        _prompted = false;
      }
    });
    _maybePrompt();
  }

  void _maybePrompt() {
    if (_unlocked || _prompted || !_enabled || !_hasSession) return;
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final success = await BiometricService.authenticate(
      reason: 'Déverrouillez CongoMedika',
    );
    if (!mounted) return;
    if (success) {
      setState(() => _unlocked = true);
    } else {
      // L'utilisateur a annulé : on ré-affiche le bouton manuellement.
      _prompted = false;
    }
  }

  Future<void> _logoutFromLockScreen() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  bool get _locked =>
      !_checking && _enabled && _hasSession && !_unlocked;

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8D3188)),
        ),
      );
    }

    if (!_locked) return widget.child;

    return Scaffold(
      backgroundColor: const Color(0xFF8D3188),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CongoMedika verrouillé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Utilisez votre empreinte digitale ou Face ID\npour accéder à l\'application',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Déverrouiller'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8D3188),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _logoutFromLockScreen,
                  child: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
