import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/auth/login.dart';

/// Récupération de compte : demande un code par email puis permet de
/// définir un nouveau mot de passe.
class MotDePasseOublie extends StatefulWidget {
  const MotDePasseOublie({super.key});

  @override
  State<MotDePasseOublie> createState() => _MotDePasseOublieState();
}

class _MotDePasseOublieState extends State<MotDePasseOublie> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF8D3188)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8D3188), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  /// Étape 1 : envoie le code de réinitialisation par email.
  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.forgotPassword(
        email: _emailController.text,
      );
      if (!mounted) return;
      _showSnack(response['message'] ?? 'Code envoyé');
      setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Étape 2 : vérifie le code et définit le nouveau mot de passe.
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.resetPassword(
        email: _emailController.text,
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showSnack(response['message'] ?? 'Mot de passe réinitialisé');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Entrez le code reçu par email'
                      : 'Mot de passe oublié ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _codeSent
                      ? 'Un code à 6 chiffres a été envoyé à ${_emailController.text}. Il expire dans 5 minutes.'
                      : 'Entrez votre adresse email pour recevoir un code de réinitialisation.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email (toujours affiché, verrouillé après envoi)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_codeSent,
                          decoration: _fieldDecoration(
                            label: 'Email',
                            hint: 'Entrez votre email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        if (_codeSent) ...[
                          const SizedBox(height: 20),

                          // Code à 6 chiffres
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: _fieldDecoration(
                              label: 'Code de vérification',
                              hint: '000000',
                              icon: Icons.pin_outlined,
                            ).copyWith(counterText: ''),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.length != 6) {
                                return 'Le code doit contenir 6 chiffres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Nouveau mot de passe
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _fieldDecoration(
                              label: 'Nouveau mot de passe',
                              hint: 'Entrez votre nouveau mot de passe',
                              icon: Icons.lock_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF8D3188),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Confirmation
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: _fieldDecoration(
                              label: 'Confirmer le mot de passe',
                              hint: 'Confirmez votre mot de passe',
                              icon: Icons.lock_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF8D3188),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer votre mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_codeSent ? _resetPassword : _sendCode),
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
                              : Text(
                                  _codeSent
                                      ? 'Réinitialiser le mot de passe'
                                      : 'Envoyer le code',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        if (_codeSent) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() => _codeSent = false),
                            child: const Text(
                              'Modifier l\'adresse email',
                              style: TextStyle(
                                color: Color(0xFF8D3188),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
