import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/app_user_model.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242735),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 42),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: StreamBuilder<List<AppUserModel>>(
                  stream: UserService().watchUsers(),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.hasError) {
                      return _DashboardMessage(
                        message: 'Unable to load users: ${usersSnapshot.error}',
                      );
                    }
                    if (!usersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<List<RequestModel>>(
                      stream: RequestService().watchAllRequests(),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.hasError) {
                          return _DashboardMessage(
                            message:
                                'Unable to load requests: '
                                '${requestSnapshot.error}',
                          );
                        }
                        if (!requestSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return StreamBuilder<List<FacilityModel>>(
                          stream: FacilityService().watchFacilities(),
                          builder: (context, facilitySnapshot) {
                            if (facilitySnapshot.hasError) {
                              return _DashboardMessage(
                                message:
                                    'Unable to load facilities: '
                                    '${facilitySnapshot.error}',
                              );
                            }
                            if (!facilitySnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return _buildDashboard(
                              context,
                              usersSnapshot.data!,
                              requestSnapshot.data!,
                              facilitySnapshot.data!,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 0),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<AppUserModel> users,
    List<RequestModel> requests,
    List<FacilityModel> facilities,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Request updates',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        const Text(
          'Here’s a quick rundown of campus activity',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                icon: Icons.list_alt,
                value: requests
                    .where((request) => request.status == 'pending')
                    .length,
                label: 'New Requests',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewMetric(
                icon: Icons.business,
                value: facilities.length,
                label: 'Facility Activities',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewMetric(
                icon: Icons.people_alt_outlined,
                value: users.length,
                label: 'New Users',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Management', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        _ManagementLink(
          icon: Icons.list_alt,
          title: 'Manage Requests',
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageRequests),
        ),
        _ManagementLink(
          icon: Icons.business,
          title: 'Manage Facilities',
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageFacilities),
        ),
        _ManagementLink(
          icon: Icons.people_alt_outlined,
          title: 'Manage Users',
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageUsers),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 23),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _ManagementLink extends StatelessWidget {
  const _ManagementLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, size: 32, color: Colors.black),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 30),
        ),
      ),
    ),
  );
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
  );
}
