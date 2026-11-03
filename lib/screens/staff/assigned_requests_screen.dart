import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import 'staff_request_details_screen.dart';

class AssignedRequestsScreen extends StatefulWidget {
  const AssignedRequestsScreen({super.key});

  @override
  State<AssignedRequestsScreen> createState() => _AssignedRequestsScreenState();
}

class _AssignedRequestsScreenState extends State<AssignedRequestsScreen> {
  var _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Accepted Requests',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              'Rooms you’ve picked to clean',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to view assigned requests.'))
          : StreamBuilder<List<RequestModel>>(
              stream: RequestService().watchAssignedRequests(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load assigned requests: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!
                    .where(
                      (request) => _showCompleted
                          ? request.status == 'completed'
                          : request.status != 'completed' &&
                                request.status != 'cancelled',
                    )
                    .toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0EBFF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            _RequestTab(
                              label: 'Accepted',
                              selected: !_showCompleted,
                              onTap: () =>
                                  setState(() => _showCompleted = false),
                            ),
                            _RequestTab(
                              label: 'Completed',
                              selected: _showCompleted,
                              onTap: () =>
                                  setState(() => _showCompleted = true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: requests.isEmpty
                          ? Center(
                              child: Text(
                                _showCompleted
                                    ? 'No completed requests yet.'
                                    : 'No tasks have been assigned to you yet.',
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                              itemCount: requests.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 5),
                              itemBuilder: (context, index) =>
                                  _AssignedTaskTile(
                                    request: requests[index],
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            StaffRequestDetailsScreen(
                                              request: requests[index],
                                            ),
                                      ),
                                    ),
                                  ),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  const _RequestTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? const Color(0xFF3478F6) : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AssignedTaskTile extends StatelessWidget {
  const _AssignedTaskTile({required this.request, required this.onTap});

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = request.status == 'completed';
    final date = request.completedAt ?? request.createdAt;
    final hour = date == null
        ? null
        : date.toLocal().hour % 12 == 0
        ? 12
        : date.toLocal().hour % 12;
    final minute = date?.toLocal().minute.toString().padLeft(2, '0');
    final suffix = date == null
        ? ''
        : date.toLocal().hour < 12
        ? 'AM'
        : 'PM';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD4D4D4)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EBFF),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.facilityId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'K Building · ${_floorLabel(request.floor)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDEBDD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      completed
                          ? 'Completed'
                          : request.status == 'pending'
                          ? 'Assigned'
                          : 'Accepted',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF299B78),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date == null ? 'Recently' : 'Today, $hour:$minute $suffix',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

String _floorLabel(int? floor) => switch (floor) {
  1 => '1st Floor',
  2 => '2nd Floor',
  3 => '3rd Floor',
  _ => 'Floor unknown',
};
