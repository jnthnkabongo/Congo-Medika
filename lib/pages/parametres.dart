import 'package:flutter/material.dart';

class Parametres extends StatefulWidget {
  const Parametres({super.key});

  @override
  State<Parametres> createState() => _ParametresState();
}

class _ParametresState extends State<Parametres> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF95057B),
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

            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Color(0xFF95057B)),
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
                  colors: [Color(0xFF95057B), Color(0xFFB0209D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95057B).withValues(alpha: 0.3),
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
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF95057B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jean Kabongo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'jean.kabongo@email.com',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.white, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSettingsSection('Compte', [
              _buildSettingsItem(
                'Informations personnelles',
                Icons.person_outline,
                () {},
              ),
              _buildSettingsItem('Sécurité', Icons.security, () {}),
              _buildSettingsItem('Moyens de paiement', Icons.payment, () {}),
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
              _buildSettingsItem(
                'Mode sombre',
                Icons.dark_mode_outlined,
                () {},
                hasSwitch: true,
                switchValue: false,
              ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: TextButton.icon(
                onPressed: () {},
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

            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF95057B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF95057B), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: (value) {},
                activeColor: const Color(0xFF95057B),
              ),
            if (!hasSwitch && trailing == null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
