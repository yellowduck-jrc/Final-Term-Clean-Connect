import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'auth_gate.dart';
import 'navigation_observer.dart';

class CleanConnectApp extends StatelessWidget {
  const CleanConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clean Connect',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20A879),
        ),
      ),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [appNavigationObserver],
      home: const AuthGate(),
    );
  }
}