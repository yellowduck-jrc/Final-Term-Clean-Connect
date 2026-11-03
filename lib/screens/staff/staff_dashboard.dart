import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import 'accept_request_dialog.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      body: uid == null
          ? const Center(child: Text('Sign in to access staff tools.'))
          : StreamBuilder<List<RequestModel>>(
              stream: RequestService().watchStaffDashboardRequests(uid),
              builder: (context, requestsSnapshot) {
                if (requestsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load dashboard: ${requestsSnapshot.error}',
                    ),
                  );
                }
                if (!requestsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<FacilityModel>>(
                  stream: FacilityService().watchFacilities(),
                  builder: (context, facilitiesSnapshot) {
                    if (facilitiesSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load facilities: '
                          '${facilitiesSnapshot.error}',
                        ),
                      );
                    }
                    if (!facilitiesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _StaffDashboardContent(
                      uid: uid,
                      requests: requestsSnapshot.data!,
                      facilities: facilitiesSnapshot.data!,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _StaffDashboardContent extends StatelessWidget {
  const _StaffDashboardContent({
    required this.uid,
    required this.requests,
    required this.facilities,
  });

  final String uid;
  final List<RequestModel> requests;
  final List<FacilityModel> facilities;

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
    final activeRooms = facilities
        .where((facility) => facility.isActive)
        .length;
    final studentRequests = requests
        .where(
          (request) =>
              request.status == 'pending' &&
              (request.assignedTo == null || request.assignedTo!.isEmpty),
        )
        .take(5)
        .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF242735),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apartment, color: Colors.white, size: 31),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Jose Rizal University\nStaff Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Profile',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Good morning!',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Keep our campus clean and safe.',
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StaffMetric(
                      icon: Icons.delete_outline,
                      value:
                          '${requests.where((r) => r.status == 'pending').length}',
                      label: 'Pending\nRequests',
                      color: const Color(0xFFE0EBFF),
                      iconColor: const Color(0xFF3980F6),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.availableRequests,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StaffMetric(
                      icon: Icons.check_circle_outline,
                      value: '$completedToday',
                      label: 'Completed\nToday',
                      color: const Color(0xFFE0EBFF),
                      iconColor: const Color(0xFF48CDA2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StaffMetric(
                      icon: Icons.access_time,
                      value: '$inProgress',
                      label: 'In Progress',
                      color: const Color(0xFFE0EBFF),
                      iconColor: const Color(0xFF7C8DF6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StaffMetric(
                      icon: Icons.meeting_room_outlined,
                      value: '$activeRooms',
                      label: 'Total Rooms',
                      color: const Color(0xFFE0EBFF),
                      iconColor: const Color(0xFF6398D8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Student Requests',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.assignedRequests,
                    ),
                    child: const Text('My Accepted'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.availableRequests,
                    ),
                    child: const Text('View All'),
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
      ],
    );
  }
}

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: BorderSide(color: iconColor.withValues(alpha: 0.35)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: 98,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: iconColor),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF242735),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
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
      border: Border.all(color: const Color(0xFFD4D4D4)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 30,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE0EBFF),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      title: Text(
        request.facilityId,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${request.issueType} · Floor ${_floorLabel(request.floor)}\n'
        '${request.description}',
        style: const TextStyle(fontSize: 10),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StaffStatusPill(status: request.status),
          const SizedBox(height: 2),
          Text(
            _timeLabel(request.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
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
        const Color(0xFFBFD3FF),
        const Color(0xFF4774D3),
      ),
      'completed' => (
        'Completed',
        const Color(0xFFBDEBDD),
        const Color(0xFF299B78),
      ),
      _ => ('Pending', const Color(0xFFFFD6B2), const Color(0xFFC17A2C)),
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

String _floorLabel(int? floor) => switch (floor) {
  1 => '1st Floor',
  2 => '2nd Floor',
  3 => '3rd Floor',
  _ => 'Floor unknown',
};

String _timeLabel(DateTime? date) {
  if (date == null) return 'Recently';
  final local = date.toLocal();
  final today = _isToday(local);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '${today ? 'Today, ' : ''}$hour:$minute $suffix';
}
