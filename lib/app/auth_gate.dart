import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/main_dashboard.dart';
import '../screens/staff/staff_dashboard.dart';
import '../services/user_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return _GateMessage(
            message:
                'Unable to check your sign-in status: '
                '${authSnapshot.error}',
          );
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading();
        }

        final user = authSnapshot.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<AppUserModel?>(
          stream: UserService().watchProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _GateMessage(
                message:
                    'Unable to load your account: '
                    '${profileSnapshot.error}',
              );
            }
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _GateLoading();
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const _GateMessage(
                message: 'Your account profile could not be found.',
              );
            }
            if (!profile.isActive) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'This account has been disabled. '
                          'Contact an administrator for help.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: FirebaseAuth.instance.signOut,
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return switch (profile.role) {
              'student' => const MainDashboard(),
              'staff' => const StaffDashboard(),
              'admin' => const AdminDashboard(),
              _ => _GateMessage(
                message:
                    'The account role "${profile.role}" is not '
                    'recognized. Ask an administrator to correct it.',
              ),
            };
          },
        );
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
