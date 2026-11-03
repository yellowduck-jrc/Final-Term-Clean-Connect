import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/app_user_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import 'accept_request_dialog.dart';
import 'staff_request_details_screen.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});

  @override
  State<AvailableRequestsScreen> createState() =>
      _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'pending';
  var _page = 0;
  static const _pageSize = 5;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Student Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Student requests waiting for staff acceptance',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: RequestService().watchAllRequests(),
        builder: (context, requestsSnapshot) {
          if (requestsSnapshot.hasError) {
            return Center(
              child: Text('Unable to load requests: ${requestsSnapshot.error}'),
            );
          }
          if (!requestsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<AppUserModel>>(
            stream: UserService().watchUsers(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Center(
                  child: Text('Unable to load users: ${usersSnapshot.error}'),
                );
              }
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildRequests(
                context,
                requestsSnapshot.data!,
                usersSnapshot.data!,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequests(
    BuildContext context,
    List<RequestModel> allRequests,
    List<AppUserModel> users,
  ) {
    final usersById = {for (final user in users) user.uid: user};
    final search = _searchController.text.trim().toLowerCase();
    final filtered = allRequests.where((request) {
      final matchesStatus =
          _statusFilter == 'all' || request.status == _statusFilter;
      final matchesFloor =
          _floorFilter == null || request.floor == _floorFilter;
      final reporter = usersById[request.reportedBy];
      final matchesSearch =
          search.isEmpty ||
          request.facilityId.toLowerCase().contains(search) ||
          request.id.toLowerCase().contains(search) ||
          request.issueType.toLowerCase().contains(search) ||
          request.description.toLowerCase().contains(search) ||
          (reporter?.fullName.toLowerCase().contains(search) ?? false);
      return matchesStatus && matchesFloor && matchesSearch;
    }).toList();

    final pageCount = (filtered.length / _pageSize).ceil();
    final page = pageCount == 0 ? 0 : _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final visible = filtered.skip(start).take(_pageSize).toList();
    final pendingCount = allRequests
        .where((request) => request.status == 'pending')
        .length;
    final inProgressCount = allRequests
        .where((request) => request.status == 'in_progress')
        .length;
    final completedCount = allRequests
        .where((request) => request.status == 'completed')
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _page = 0),
                  decoration: InputDecoration(
                    hintText: 'Search by room, student, or request...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _page = 0);
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Filter requests',
                onPressed: () => _showFilters(context),
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            children: [
              _StatusFilterChip(
                label: 'All (${allRequests.length})',
                selected: _statusFilter == 'all',
                onTap: () => _selectStatus('all'),
              ),
              _StatusFilterChip(
                label: 'Pending ($pendingCount)',
                selected: _statusFilter == 'pending',
                color: const Color(0xFFFFF3E4),
                onTap: () => _selectStatus('pending'),
              ),
              _StatusFilterChip(
                label: 'In Progress ($inProgressCount)',
                selected: _statusFilter == 'in_progress',
                color: const Color(0xFFE7F0FF),
                onTap: () => _selectStatus('in_progress'),
              ),
              _StatusFilterChip(
                label: 'Completed ($completedCount)',
                selected: _statusFilter == 'completed',
                color: const Color(0xFFE4F4E9),
                onTap: () => _selectStatus('completed'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No requests match your filters.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final request = visible[index];
                    return _StudentRequestCard(
                      request: request,
                      reporter:
                          usersById[request.reportedBy]?.fullName ?? 'Student',
                      onTap: request.status == 'pending'
                          ? () => showAcceptRequestDialog(context, request)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    StaffRequestDetailsScreen(request: request),
                              ),
                            ),
                    );
                  },
                ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${page + 1} of $pageCount'),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: page + 1 < pageCount
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _selectStatus(String status) {
    setState(() {
      _statusFilter = status;
      _page = 0;
    });
  }

  Future<void> _showFilters(BuildContext context) async {
    final selectedFloor = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Filter by floor')),
            for (final floor in const [-1, 1, 2, 3])
              ListTile(
                title: Text(floor == -1 ? 'All floors' : 'Floor $floor'),
                onTap: () => Navigator.pop(context, floor),
              ),
          ],
        ),
      ),
    );
    if (selectedFloor != null) {
      setState(() {
        _floorFilter = selectedFloor == -1 ? null : selectedFloor;
        _page = 0;
      });
    }
  }

  int? _floorFilter;
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF3478F6),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: selected ? color : color.withValues(alpha: 0.55),
      selectedColor: color,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 10,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _StudentRequestCard extends StatelessWidget {
  const _StudentRequestCard({
    required this.request,
    required this.reporter,
    required this.onTap,
  });

  final RequestModel request;
  final String reporter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD8DCE2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE0EBFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                request.issueType.toLowerCase().contains('repair')
                    ? Icons.build_outlined
                    : Icons.cleaning_services_outlined,
                color: const Color(0xFF27354A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.facilityId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    request.issueType,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reporter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RequestStatus(status: request.status),
                const SizedBox(height: 5),
                Text(
                  _requestDateLabel(request.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (status) {
      'in_progress' => (
        'In Progress',
        const Color(0xFFDCEAFF),
        const Color(0xFF2157A4),
      ),
      'completed' => (
        'Completed',
        const Color(0xFFDDF2E2),
        const Color(0xFF276A42),
      ),
      'cancelled' => ('Cancelled', const Color(0xFFEAEAEA), Colors.black54),
      _ => ('Pending', const Color(0xFFFFD9C6), const Color(0xFF944A22)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }
}

String _requestDateLabel(DateTime? date) {
  if (date == null) return 'Recently';
  final local = date.toLocal();
  final now = DateTime.now();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final dayLabel = day == today
      ? 'Today'
      : day == today.subtract(const Duration(days: 1))
      ? 'Yesterday'
      : '${local.month}/${local.day}';
  return '$dayLabel, $hour:$minute $suffix';
}
