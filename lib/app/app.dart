import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20A879),
        ),
        textButtonTheme: TextButtonThemeData(
          style: const ButtonStyle(
            mouseCursor: WidgetStateMouseCursor.clickable,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: const ButtonStyle(
            mouseCursor: WidgetStateMouseCursor.clickable,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: const ButtonStyle(
            mouseCursor: WidgetStateMouseCursor.clickable,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: const ButtonStyle(
            mouseCursor: WidgetStateMouseCursor.clickable,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: const ButtonStyle(
            mouseCursor: WidgetStateMouseCursor.clickable,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          mouseCursor: WidgetStateMouseCursor.clickable,
        ),
      ),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [appNavigationObserver],
      home: const AuthGate(),
    );
  }
}