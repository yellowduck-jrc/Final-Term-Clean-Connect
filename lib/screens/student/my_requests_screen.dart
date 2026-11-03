import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/navigation_observer.dart';
import '../../app/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/request_card.dart';
import '../dashboard/main_dashboard.dart';
import '../maps/floor_map_screen.dart';
import '../shared/notifications_screen.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My requests',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track the clean-up requests you have sent.',
                style: TextStyle(fontSize: 11),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: user == null
                    ? const Center(
                        child: Text(
                          'Please log in to view your requests.',
                        ),
                      )
                    : StreamBuilder<List<RequestModel>>(
                        stream: RequestService()
                            .watchRequestsByReporter(user.uid),

                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Unable to load your requests: '
                                '${snapshot.error}',
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final requests = snapshot.data ?? [];

                          if (requests.isEmpty) {
                            return const Center(
                              child: Text(
                                'No requests submitted yet.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final request = requests[index];

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 9,
                                ),
                                child: RequestCard(
                                  request: request,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          RequestDetailsScreen(
                                            request: request,
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 39,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FloorMapScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF20A879),
                  ),
                  label: const Text(
                    'Create a request',
                    style: TextStyle(
                      color: Color(0xFF20A879),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFBDBDBD),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainDashboard(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.map);
          } else if (index == 3) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
      ),
    );
  }
}