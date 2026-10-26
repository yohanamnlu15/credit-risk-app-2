import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/custom_page_route.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const CreditRiskApp());
}

class CreditRiskApp extends StatelessWidget {
  const CreditRiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrediPredict',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return AppPageTransitions.fade(const SplashScreen());
          case AppRoutes.login:
            return AppPageTransitions.fade(const LoginScreen());
          case AppRoutes.register:
            return AppPageTransitions.slideRight(const RegisterScreen());
          default:
            return AppPageTransitions.fade(const LoginScreen());
        }
      },
    );
  }
}