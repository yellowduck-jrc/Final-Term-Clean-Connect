import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/request_thumbnail.dart';
import '../../widgets/staff_bottom_nav.dart';
import 'accept_request_dialog.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF202127),
      bottomNavigationBar: const StaffBottomNav(selectedIndex: 0),
      body: uid == null
          ? const Center(child: Text('Sign in to access staff tools.'))
          : StreamBuilder<List<RequestModel>>(
              stream: RequestService().watchStaffDashboardRequests(uid),
              builder: (context, requestsSnapshot) {
                if (requestsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load dashboard: ${requestsSnapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!requestsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _StaffDashboardContent(
                  uid: uid,
                  requests: requestsSnapshot.data!,
                );
              },
            ),
    );
  }
}

class _StaffDashboardContent extends StatelessWidget {
  const _StaffDashboardContent({required this.uid, required this.requests});

  final String uid;
  final List<RequestModel> requests;

  @override
  Widget build(BuildContext context) {
    final assigned = requests
        .where(
          (request) =>
              request.assignedTo == uid && request.status != 'cancelled',
        )
        .toList();
    final completedToday = assigned.where((request) {
      if (request.status != 'completed') return false;
      final completionDate = request.completedAt ?? request.createdAt;
      return completionDate != null && _isToday(completionDate);
    }).length;
    final inProgress = assigned
        .where((request) => request.status == 'in_progress')
        .length;
    final studentRequests = requests
        .where(
          (request) =>
              request.reportedBy.trim().isNotEmpty &&
              request.status == 'pending' &&
              (request.assignedTo == null || request.assignedTo!.isEmpty),
        )
        .take(3)
        .toList();
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoUrl = currentUser?.photoURL;
    final staffName = _staffDisplayName(currentUser);

    return Container(
      color: const Color(0xFF242735),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF242735),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 48),
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
                      tooltip: 'Notifications',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE96886),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 21,
                          backgroundColor: const Color(0xFFE8E8E8),
                          backgroundImage: photoUrl == null
                              ? null
                              : NetworkImage(photoUrl),
                          child: photoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                  size: 26,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $staffName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF292D3C),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Help keep your campus fresh and welcoming.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _CampusCleanlinessCard(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StaffMetric(
                          icon: Icons.check_circle_outline,
                          value: '$completedToday',
                          label: 'Completed\nToday',
                          iconFill: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StaffMetric(
                          icon: Icons.access_time,
                          value: '$inProgress',
                          label: 'In Progress',
                          iconFill: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StaffMetric(
                          icon: Icons.delete_outline,
                          value: requests
                              .where((r) => r.status == 'pending')
                              .length
                              .toString(),
                          label: 'Pending\nRequest',
                          iconFill: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.availableRequests,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pending Tasks',
                          style: TextStyle(
                            color: Color(0xFF292D3C),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _PendingTasksBanner(
                    count: requests
                        .where(
                          (request) =>
                              request.status == 'in_progress' &&
                              request.assignedTo == uid,
                        )
                        .length,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.assignedTasks,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Requests',
                          style: TextStyle(
                            color: Color(0xFF292D3C),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.availableRequests,
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View All  ›',
                          style: TextStyle(
                            color: Color(0xFF3977FF),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (studentRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No student requests are waiting for acceptance.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final request in studentRequests)
                      _StaffRequestTile(
                        request: request,
                        onTap: () => showAcceptRequestDialog(context, request),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusCleanlinessCard extends StatelessWidget {
  const _CampusCleanlinessCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 110,
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
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox.expand(
                child: CircularProgressIndicator(
                  value: .86,
                  strokeWidth: 16,
                  backgroundColor: Color(0xFF174A00),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF399849),
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
        const SizedBox(width: 16),
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

class _PendingTasksBanner extends StatelessWidget {
  const _PendingTasksBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF399849),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          children: [
            Text(
              count.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Tasks Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Let’s get them done and keep our campus clean and organized.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 19),
          ],
        ),
      ),
    ),
  );
}

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.iconFill = false,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool iconFill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 106,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFB7B7B7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconFill ? const Color(0xFF399849) : null,
                border: iconFill
                    ? null
                    : Border.all(color: const Color(0xFF399849), width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconFill ? Colors.white : const Color(0xFF399849),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26.5,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF399849),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.05,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StaffRequestTile extends StatelessWidget {
  const _StaffRequestTile({required this.request, required this.onTap});

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFBFE4D9),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Row(
            children: [
              RequestThumbnail(request: request, width: 56, height: 56),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.description.isEmpty
                          ? request.issueType
                          : request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF399849),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      request.facilityId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF59645F),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF4D5753),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Floor ${request.floor ?? '?'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF59645F),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.chevron_right, size: 20),
                  const SizedBox(height: 8),
                  _StaffStatusPill(status: request.status),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StaffStatusPill extends StatelessWidget {
  const _StaffStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (status) {
      'in_progress' => (
        'In Progress',
        const Color(0xFFF0BE81),
        const Color(0xFFB36B12),
      ),
      'completed' => (
        'Completed',
        const Color(0xFFBDEBDD),
        const Color(0xFF299B78),
      ),
      _ => ('Open', const Color(0xFFEE857F), const Color(0xFFB34740)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

String _staffDisplayName(User? user) {
  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final email = user?.email;
  if (email != null && email.contains('@')) return email.split('@').first;
  return 'Staff';
}
