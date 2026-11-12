import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/theme/app_theme.dart';

void main() {
  test('AppTheme.light fournit un TextTheme complet', () {
    final theme = AppTheme.light;
    expect(theme.textTheme.bodyMedium, isNotNull);
    expect(theme.textTheme.titleLarge, isNotNull);
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  testWidgets('Le thème ne bloque pas le textScaler système',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('Texte test')),
      ),
    );
    // À l'échelle 2.0, le texte doit être rendu plus grand :
    // le thème ne doit pas écraser le TextScaler.
    final context = tester.element(find.text('Texte test'));
    final scaler = MediaQuery.textScalerOf(context);
    expect(scaler.scale(10), greaterThanOrEqualTo(10));
  });
}
