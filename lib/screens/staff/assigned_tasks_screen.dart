import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/request_thumbnail.dart';
import '../../widgets/staff_bottom_nav.dart';
import 'staff_request_details_screen.dart';

class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({super.key});

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  var _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF202127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Tasks', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      bottomNavigationBar: const StaffBottomNav(selectedIndex: 1),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ColoredBox(
          color: Colors.white,
          child: uid == null
              ? const Center(child: Text('Sign in to view assigned tasks.'))
              : StreamBuilder<List<RequestModel>>(
                  stream: RequestService().watchAssignedRequests(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Unable to load assigned tasks: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assigned = snapshot.data!
                        .where(
                          (request) =>
                              request.status == 'in_progress' ||
                              request.status == 'completed',
                        )
                        .toList();
                    final requests = switch (_selectedFilter) {
                      1 => assigned
                          .where((request) => request.status == 'in_progress')
                          .toList(),
                      2 => assigned
                          .where((request) => request.status == 'completed')
                          .toList(),
                      _ => assigned,
                    };
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            children: [
                              _TaskFilter(
                                label: 'All Accepted',
                                selected: _selectedFilter == 0,
                                onTap: () => setState(() => _selectedFilter = 0),
                              ),
                              const SizedBox(width: 6),
                              _TaskFilter(
                                label: 'In Progress',
                                selected: _selectedFilter == 1,
                                onTap: () => setState(() => _selectedFilter = 1),
                              ),
                              const SizedBox(width: 6),
                              _TaskFilter(
                                label: 'Completed',
                                selected: _selectedFilter == 2,
                                onTap: () => setState(() => _selectedFilter = 2),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: requests.isEmpty
                              ? const Center(child: Text('No assigned tasks here yet.'))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  itemCount: requests.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final request = requests[index];
                                    return _AssignedTaskCard(
                                      request: request,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => StaffRequestDetailsScreen(
                                            request: request,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _TaskFilter extends StatelessWidget {
  const _TaskFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 26,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF399849) : Colors.white,
          foregroundColor: selected ? Colors.white : const Color(0xFF292929),
          side: BorderSide(color: selected ? const Color(0xFF399849) : const Color(0xFFBDBDBD)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
        ),
        child: FittedBox(child: Text(label)),
      ),
    ),
  );
}

class _AssignedTaskCard extends StatelessWidget {
  const _AssignedTaskCard({required this.request, required this.onTap});

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFC9E9E0),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            RequestThumbnail(request: request, width: 54, height: 54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.description.isEmpty ? request.issueType : request.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${request.facilityId} ${request.issueType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.black54),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '⌖  Floor ${request.floor ?? '?'} | ${request.facilityId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onTap,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right, size: 16),
              label: const Text('View Details', style: TextStyle(fontSize: 8)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1675E8),
                padding: EdgeInsets.zero,
                minimumSize: const Size(68, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
