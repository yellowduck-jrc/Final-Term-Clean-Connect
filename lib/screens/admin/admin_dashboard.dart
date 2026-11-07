import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/app_user_model.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

const _adminGreen = Color(0xFF399849);
const _adminMint = Color(0xFFBFE4D9);

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242735),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF242735),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: () async {
                        try {
                          await AuthService().signOut();
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
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                    const Expanded(
                      child: Center(
                        child: Image(
                          image: AssetImage('assets/auth/broom.png'),
                          width: 52,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Request updates',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.notifications),
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
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
                        return const Center(child: CircularProgressIndicator());
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
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 0),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<AppUserModel> users,
    List<RequestModel> requests,
    List<FacilityModel> facilities,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final admin = users.where((item) => item.uid == user?.uid);
    final adminName = admin.isEmpty
        ? user?.displayName ?? 'Admin'
        : admin.first.fullName;
    final now = DateTime.now();
    final pendingToday = requests.where((request) {
      final createdAt = request.createdAt;
      return request.status == 'pending' &&
          createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
    final activeFacilities = facilities
        .where((facility) => facility.isActive)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 18),
      children: [
        Row(
          children: [
            _AdminAvatar(photoUrl: user?.photoURL),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $adminName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF242735),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Help keep your campus fresh and welcoming.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Text(
          'Requests Update Today',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                icon: Icons.description_outlined,
                value: pendingToday,
                label: 'Pending Request',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _OverviewMetric(
                icon: Icons.business,
                value: activeFacilities,
                label: 'Facility Activities',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _OverviewMetric(
                icon: Icons.person_add_alt_1,
                value: users.length,
                label: 'User Activity',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _CampusCleanlinessCard(),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            'Management',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        _ManagementLink(
          icon: Icons.description,
          title: 'Manage Requests',
          subtitle: 'Click here to manage all the requests today!',
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageRequests),
        ),
        _ManagementLink(
          icon: Icons.person_add_alt_1,
          title: 'Manage Users',
          subtitle: 'Click here to manage all the users today!',
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageUsers),
        ),
      ],
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE34563)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF2F2F2),
                child: Icon(Icons.person, color: Color(0xFF9A9A9A)),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF2F2F2),
                  child: Icon(Icons.person, color: Color(0xFF9A9A9A)),
                ),
              ),
      ),
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
    height: 112,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _adminGreen,
          ),
          child: Icon(icon, size: 25, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: _adminGreen,
            fontSize: 27,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _adminGreen, fontSize: 9, height: 1.1),
        ),
        const Text(
          'for today',
          style: TextStyle(color: Colors.black54, fontSize: 8, height: 1),
        ),
      ],
    ),
  );
}

class _CampusCleanlinessCard extends StatelessWidget {
  const _CampusCleanlinessCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 116,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF36994E), Color(0xFF143D24)],
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox.expand(
                child: CircularProgressIndicator(
                  value: .86,
                  strokeWidth: 17,
                  backgroundColor: Color(0xFF174A00),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _adminGreen,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '86%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 17),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus Cleanliness',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3),
            Text(
              '↑ +2%',
              style: TextStyle(
                color: Color(0xFF24F32D),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'vs. last week',
              style: TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ManagementLink extends StatelessWidget {
  const _ManagementLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: _adminMint,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: SizedBox(
          height: 67,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 42, color: _adminGreen),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _adminGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: Icon(Icons.chevron_right, size: 22),
              ),
            ],
          ),
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
