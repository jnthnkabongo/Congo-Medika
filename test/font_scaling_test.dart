import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/administrateurs/main_menu.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/auth/register.dart';
import 'package:frontend/auth/verification.dart';
import 'package:frontend/theme/app_theme.dart';

/// Vérifie qu'un écran ne produit aucune exception de rendu
/// (RenderFlex overflow, texte rogné, etc.) à un facteur d'échelle donné.
Widget _wrap(Widget child, double scale) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  const scales = [0.8, 1.0, 1.2, 1.3, 1.5, 1.8, 2.0];

  for (final scale in scales) {
    testWidgets('Login : aucun débordement à ${scale}x', (tester) async {
      await tester.pumpWidget(_wrap(const Login(), scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Connectez-vous à votre compte'), findsOneWidget);
    });

    testWidgets('Vérification (login) : aucun débordement à ${scale}x',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Verification(
            challengeId: 'test-challenge',
            isLogin: true,
            email: 'patient@example.com',
            role: 'patient',
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Renvoyer le code'), findsOneWidget);
    });

    testWidgets('Vérification (inscription) : aucun débordement à ${scale}x',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Verification(
            challengeId: 'test-challenge',
            isLogin: false,
            email: 'patient@example.com',
            role: 'patient',
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Inscription : aucun débordement à ${scale}x', (tester) async {
      await tester.pumpWidget(_wrap(const Register(), scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // Le menu admin n'est pas protégé par AuthGuard : on peut le tester
    // directement. Les pages chargent leurs données en arrière-plan et
    // gèrent les erreurs réseau elles-mêmes.
    if (scale == 1.0 || scale == 1.5 || scale == 2.0) {
      testWidgets('Menu admin : aucun débordement à ${scale}x',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(_wrap(const MainMenuAdmin(), scale));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        // Tous les onglets doivent rester visibles, libellés complets.
        expect(find.text('Rendez-vous'), findsWidgets);
        expect(find.text('Paramètres'), findsWidgets);
      });
    }
  }
}
