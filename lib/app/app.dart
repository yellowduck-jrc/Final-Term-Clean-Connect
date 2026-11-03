import 'package:flutter/material.dart';
import 'app_routes.dart';

class CleanConnectApp extends StatelessWidget {
  const CleanConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clean Connect',
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}