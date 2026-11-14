import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/main_menu.dart';
import '../administrateurs/main_menu.dart';
import 'login.dart';
import '../services/auth_service.dart';

class Verification extends StatefulWidget {
  final String challengeId;
  final bool isLogin;
  final String email;
  final String role;

  const Verification({
    super.key,
    required this.challengeId,
    this.isLogin = false,
    required this.email,
    required this.role,
  });

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  late String _challengeId;

  @override
  void initState() {
    super.initState();
    _challengeId = widget.challengeId;
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    String code = _codeControllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code doit contenir 6 chiffres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;

      if (widget.isLogin) {
        // Vérification du code de connexion (2FA)
        response = await AuthService.verifyLoginCode(
          challengeId: _challengeId,
          code: code,
        );
      } else {
        // Vérification de l'email
        response = await AuthService.verifyEmail(
          challengeId: _challengeId,
          code: code,
        );
      }

      // Sauvegarder le token et les données utilisateur
      if (response.containsKey('accessToken')) {
        await AuthService.sauvegardeDonneesUser(
          AuthService.tokenKey,
          response['accessToken'],
        );
        await AuthService.sauvegardeDonneesUser(
          AuthService.refreshTokenKey,
          response['refreshToken'],
        );
        await AuthService.sauvegardeDonneesUser(
          AuthService.userKey,
          response['user'],
        );

        // Sauvegarder le token Meet SaaS et organizationId si disponibles
        if (response.containsKey('meetSaaSToken') &&
            response['meetSaaSToken'] != null) {
          await AuthService.sauvegardeDonneesUser(
            'meetSaaSToken',
            response['meetSaaSToken']['token'],
          );
          await AuthService.sauvegardeDonneesUser(
            'organizationId',
            response['meetSaaSToken']['organizationId'],
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Vérification réussie'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirection : la vérification email (isLogin=false) ne
        // retourne pas de token → retour au login. La vérification
        // 2FA (isLogin=true) retourne un token → menu selon le rôle.
        if (!widget.isLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
          return;
        }

        // Redirection selon le rôle renvoyé par le backend
        // (détecté automatiquement via l'email), avec repli sur le rôle connu.
        final userRole =
            (response['user'] as Map<String, dynamic>?)?['role'] ?? widget.role;
        if (userRole == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenuAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenu()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = widget.isLogin
          ? await AuthService.resendLoginCode(
              email: widget.email,
              role: widget.role,
            )
          : await AuthService.resendVerification(
              email: widget.email,
              role: widget.role,
            );

      // Le backend invalide l'ancien code et en crée un nouveau :
      // il faut utiliser le nouveau challengeId pour la vérification.
      if (response['challengeId'] != null) {
        _challengeId = response['challengeId'];
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Code renvoyé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du renvoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/logo-congo-medika-1.webp',
                    width: 250,
                    height: 250,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérification de votre compte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Entrez le code de vérification envoyé à votre adresse email',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 0 : 4,
                                right: index == 5 ? 0 : 4,
                              ),
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _codeControllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF8D3188),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) =>
                                      _onCodeChanged(value, index),
                                  onSubmitted: (value) {
                                    if (index == 5) {
                                      _verifyCode();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D3188),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Vérifier',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: const Color(0xFF8D3188),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  '© 2026 Congo Medika. Tous droits réservés.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
