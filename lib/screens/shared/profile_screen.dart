import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/app_user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
      ),
      body: authUser == null
          ? const Center(child: Text('Sign in to view your profile.'))
          : FutureBuilder<AppUserModel?>(
              future: UserService().getUser(authUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load your profile: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profile = snapshot.data;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      child: Icon(Icons.person_outline, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        profile?.fullName ?? authUser.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(child: Text(profile?.email ?? authUser.email ?? '')),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Account role'),
                      subtitle: Text(profile?.role ?? 'Unavailable'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Account status'),
                      subtitle: Text(
                        profile == null
                            ? 'Profile not found'
                            : profile.isActive
                            ? 'Active'
                            : 'Disabled',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unable to sign out: $error'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
