import 'package:flutter/material.dart';
import 'package:frontend/pages/profil_patient.dart';
import 'package:frontend/pages/paiements.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/pages/edit_profile_bottom_sheet.dart';
import 'package:frontend/auth/login.dart';
import 'dart:convert';

class Parametres extends StatefulWidget {
  const Parametres({super.key});

  @override
  State<Parametres> createState() => _ParametresState();
}

class _ParametresState extends State<Parametres> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getDonneesUser(AuthService.userKey);
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await AuthService.logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              );
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile() {
    if (_userData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(userData: _userData!),
    ).then((result) {
      if (result == true) {
        _loadUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paramètres',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            GestureDetector(
              onTap: _userData != null ? _showEditProfile : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  image:
                      _userData != null &&
                          _userData!['avatar'] != null &&
                          _userData!['avatar'].toString().isNotEmpty
                      ? DecorationImage(
                          image:
                              _userData!['avatar'].toString().startsWith(
                                'data:',
                              )
                              ? MemoryImage(
                                  base64Decode(
                                    _userData!['avatar'].toString().split(
                                      ',',
                                    )[1],
                                  ),
                                )
                              : NetworkImage(_userData!['avatar'].toString()),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (_userData == null ||
                        _userData!['avatar'] == null ||
                        _userData!['avatar'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF8D3188))
                    : null,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D3188), Color(0xFFB0209D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8D3188).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      image:
                          _userData != null &&
                              _userData!['avatar'] != null &&
                              _userData!['avatar'].toString().isNotEmpty
                          ? DecorationImage(
                              image:
                                  _userData!['avatar'].toString().startsWith(
                                    'data:',
                                  )
                                  ? MemoryImage(
                                      base64Decode(
                                        _userData!['avatar'].toString().split(
                                          ',',
                                        )[1],
                                      ),
                                    )
                                  : NetworkImage(
                                      _userData!['avatar'].toString(),
                                    ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (_userData == null ||
                            _userData!['avatar'] == null ||
                            _userData!['avatar'].toString().isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF8D3188),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? 'Utilisateur'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData?['email'] ?? 'email@example.com',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                  ),
                  GestureDetector(
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSettingsSection('Compte', [
              _buildSettingsItem(
                'Informations personnelles',
                Icons.person_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilPatient(),
                    ),
                  );
                },
              ),
              // _buildSettingsItem('Sécurité', Icons.security, () {}),
              _buildSettingsItem('Moyens de paiement', Icons.payment, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Paiements()),
                );
              }),
            ]),
            const SizedBox(height: 16),

            _buildSettingsSection('Préférences', [
              _buildSettingsItem(
                'Notifications',
                Icons.notifications_outlined,
                () {},
                hasSwitch: true,
                switchValue: true,
              ),
              _buildSettingsItem(
                'Langue',
                Icons.language,
                () {},
                trailing: 'Français',
              ),
              // _buildSettingsItem(
              //   'Mode sombre',
              //   Icons.dark_mode_outlined,
              //   () {},
              //   hasSwitch: true,
              //   switchValue: false,
              // ),
            ]),
            const SizedBox(height: 16),

            _buildSettingsSection('Support', [
              _buildSettingsItem('Centre d\'aide', Icons.help_outline, () {}),
              _buildSettingsItem(
                'Contactez-nous',
                Icons.contact_support,
                () {},
              ),
              _buildSettingsItem(
                'Conditions d\'utilisation',
                Icons.description_outlined,
                () {},
              ),
              _buildSettingsItem(
                'Politique de confidentialité',
                Icons.privacy_tip_outlined,
                () {},
              ),
            ]),
            const SizedBox(height: 16),

            _buildSettingsSection('Autre', [
              _buildSettingsItem('À propos', Icons.info_outline, () {}),
              _buildSettingsItem(
                'Noter l\'application',
                Icons.star_outline,
                () {},
              ),
            ]),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: TextButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text(
            //   'Version 1.0.0',
            //   style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            //   textAlign: TextAlign.center,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? trailing,
    bool hasSwitch = false,
    bool switchValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8D3188).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF8D3188), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: (value) {},
                activeThumbColor: const Color(0xFF8D3188),
              ),
            if (!hasSwitch && trailing == null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
