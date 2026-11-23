import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/auth/onboarding.dart';
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
        MaterialPageRoute(builder: (context) => const Onboarding()),
        (route) => false,
      );
    }
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CongoMedika',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: _onboardingCompleted == null
          ? const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8D3188),
                ),
              ),
            )
          : _onboardingCompleted!
              ? const Login()
              : const Onboarding(),
      builder: (context, child) =>
          CallNotificationManager(child: child ?? const SizedBox.shrink()),
    );
  }
}
