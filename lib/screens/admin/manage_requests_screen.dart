import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';

import '../../models/app_user_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests'),
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
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
            stream: UserService().watchUsersByRole('staff'),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Center(
                  child: Text('Unable to load users: ${usersSnapshot.error}'),
                );
              }
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final requests = requestsSnapshot.data!;
              if (requests.isEmpty) {
                return const Center(child: Text('No requests yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _RequestSummaryCard(
                  request: requests[index],
                  users: usersSnapshot.data!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _AdminRequestDetailsScreen(request: requests[index]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({
    required this.request,
    required this.users,
    required this.onTap,
  });

  final RequestModel request;
  final List<AppUserModel> users;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assignee = users.where((user) => user.uid == request.assignedTo);
    final assignedName = assignee.isEmpty ? 'Assign' : assignee.first.fullName;
    return Material(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              Text(
                '${request.id} · ${request.issueType}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                '⌖ Floor ${request.floor ?? '?'} · ${request.facilityId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              const Text('Personnel Assigned', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '♟  $assignedName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RequestStatusPill(status: request.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestStatusPill extends StatelessWidget {
  const _RequestStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (status) {
      'completed' => ('Complete', const Color(0xFFC9F4D1), Colors.green),
      'in_progress' => (
        'In progress',
        const Color(0xFFF7EFB9),
        const Color(0xFFB7A43B),
      ),
      'cancelled' => ('Cancelled', const Color(0xFFE8E8E8), Colors.black54),
      _ => ('Open', const Color(0xFFF7C6C6), Colors.redAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }
}

class _AdminRequestDetailsScreen extends StatefulWidget {
  const _AdminRequestDetailsScreen({required this.request});

  final RequestModel request;

  @override
  State<_AdminRequestDetailsScreen> createState() =>
      _AdminRequestDetailsScreenState();
}

class _AdminRequestDetailsScreenState
    extends State<_AdminRequestDetailsScreen> {
  late String _status = widget.request.status;
  late String? _assignedTo = widget.request.assignedTo;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Request Overview'),
      ),
      body: StreamBuilder<List<AppUserModel>>(
        stream: UserService().watchUsersByRole('staff'),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.hasError) {
            return Center(
              child: Text('Unable to load staff: ${usersSnapshot.error}'),
            );
          }
          if (!usersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final staff = usersSnapshot.data!
              .where((user) => user.role.toLowerCase() == 'staff')
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            children: [
              _DetailSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _BlueSquare(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _dateLabel(request.createdAt),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('Description', style: TextStyle(fontSize: 11)),
                    Text(
                      request.description,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _DetailSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Floor ${request.floor ?? '?'} · Near ${request.facilityId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Map preview unavailable'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _DetailSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Worker',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      initialValue: staff.any((user) => user.uid == _assignedTo)
                          ? _assignedTo
                          : null,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        for (final user in staff)
                          DropdownMenuItem<String?>(
                            value: user.uid,
                            child: Text(user.fullName),
                          ),
                      ],
                      onChanged: (value) => setState(() => _assignedTo = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _DetailSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final status in const [
                          'pending',
                          'in_progress',
                          'completed',
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(_statusLabel(status)),
                                selected: _status == status,
                                onSelected: (_) =>
                                    setState(() => _status = status),
                                showCheckmark: false,
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFFF7EFB9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _DetailSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Activity',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '●  Request Made\n    ${_dateLabel(request.createdAt)} by Student',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => _saveChanges(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF69CFA4),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 1),
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      await RequestService().updateAssignmentAndStatus(
        requestId: widget.request.id,
        status: _status,
        assignedTo: _assignedTo,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _BlueSquare extends StatelessWidget {
  const _BlueSquare();

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF70A6D4),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'in_progress' => 'In Progress',
  'completed' => 'Complete',
  _ => 'Pending',
};

String _dateLabel(DateTime? date) {
  if (date == null) return 'Date unavailable';
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '${local.month}/${local.day}/${local.year} · $hour:$minute $meridiem';
}
