
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/maps/floor_map_screen.dart';

Future<void> main() async {
  // Initialize Flutter before using Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Connect the application to Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the application.
  runApp(const CleanConnectApp());
}

class CleanConnectApp extends StatelessWidget {
  const CleanConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clean Connect',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: TestRoomScreen(),
      ),
    );
  }
}
