import 'package:flutter/material.dart';
import 'package:frontend/pages/calendrier.dart';
import 'package:frontend/pages/dashboard.dart';
import 'package:frontend/pages/consultations.dart';
import 'package:frontend/pages/journal.dart';
import 'package:frontend/pages/parametres.dart';
import 'package:frontend/widgets/auth_guard.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Dashboard(),
    Consultations(),
    Journal(),
    Calendriers(),
    Parametres(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'Accueil',
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.medical_services_outlined,
                      selectedIcon: Icons.medical_services_rounded,
                      label: 'Consultations',
                      index: 1,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.phone_outlined,
                      selectedIcon: Icons.phone_rounded,
                      label: 'Appels',
                      index: 2,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.calendar_today_outlined,
                      selectedIcon: Icons.calendar_today_rounded,
                      label: 'Rendez-vous',
                      index: 3,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                      label: 'Paramètres',
                      index: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8D3188).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSelected ? selectedIcon : icon,
                key: ValueKey(isSelected ? selectedIcon : icon),
                color: isSelected
                    ? const Color(0xFF8D3188)
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            // FittedBox : le libellé rétrécit si nécessaire pour rester
            // entièrement visible lorsque la police système est agrandie.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF8D3188)
                      : Colors.grey.shade600,
                  fontSize: isSelected ? 10 : 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
