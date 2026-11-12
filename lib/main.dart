import 'package:flutter/material.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/call_notification_manager.dart';
import 'package:frontend/services/http_interceptor.dart';

// GlobalKey pour le Navigator global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Configurer le callback pour la redirection en cas d'expiration du token
  onAuthExpired = () {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CongoMedika',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const Login(),
      builder: (context, child) =>
          CallNotificationManager(child: child ?? const SizedBox.shrink()),
    );
  }
}
