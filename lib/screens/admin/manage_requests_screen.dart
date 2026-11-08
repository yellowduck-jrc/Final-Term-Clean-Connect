import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';

import '../../models/app_user_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../widgets/request_thumbnail.dart';

const _requestGreen = Color(0xFF2FA455);
const _requestMint = Color(0xFFD1EEE5);

class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  Future<void> _deleteRequest(
    BuildContext context,
    RequestModel request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This permanently deletes the request and its task history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await RequestService().deleteRequest(request.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete request: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242735),
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Request',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Track the clean-up requests you have sent.',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<RequestModel>>(
                  stream: RequestService().watchAllRequests(),
                  builder: (context, requestsSnapshot) {
                    if (requestsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load requests: ${requestsSnapshot.error}',
                        ),
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
                            child: Text(
                              'Unable to load users: ${usersSnapshot.error}',
                            ),
                          );
                        }
                        if (!usersSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final requests = requestsSnapshot.data!;
                        if (requests.isEmpty) {
                          return const Center(child: Text('No requests yet.'));
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          itemCount: requests.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            return _RequestSummaryCard(
                              request: request,
                              users: usersSnapshot.data!,
                              onDelete: () => _deleteRequest(context, request),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => _AdminRequestDetailsScreen(
                                    request: request,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.map),
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text(
                      'Create a request',
                      style: TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _requestGreen,
                      side: const BorderSide(color: Color(0xFFBDBDBD)),
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    required this.onDelete,
  });

  final RequestModel request;
  final List<AppUserModel> users;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final assignee = users.where((user) => user.uid == request.assignedTo);
    final assignedName = assignee.isEmpty ? 'Assign' : assignee.first.fullName;
    return Material(
      color: _requestMint,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RequestThumbnail(request: request, width: 52, height: 52),
              const SizedBox(width: 7),
              Expanded(
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
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    Text(
                      '${request.id} ${request.issueType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Floor ${request.floor ?? '?'} | ${request.facilityId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Personnel Assigned',
                      style: TextStyle(fontSize: 8),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 17,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Color(0xFF292929),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    assignedName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: assignee.isEmpty
                                          ? _requestGreen
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _RequestCardAction(
                          icon: Icons.edit,
                          color: _requestGreen,
                          tooltip: 'Edit request',
                          onPressed: onTap,
                        ),
                        const SizedBox(width: 3),
                        _RequestCardAction(
                          icon: Icons.delete,
                          color: Colors.red,
                          tooltip: 'Delete request',
                          onPressed: onDelete,
                        ),
                        const SizedBox(width: 5),
                        _RequestStatusPill(status: request.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCardAction extends StatelessWidget {
  const _RequestCardAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 20,
      height: 20,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 11),
        ),
      ),
    ),
  );
}

class _RequestStatusPill extends StatelessWidget {
  const _RequestStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (status) {
      'completed' => ('Complete', const Color(0xFFC9F4D1), Colors.green),
      'in_progress' => (
        'Inprogress',
        const Color(0xFFEAC27A),
        const Color(0xFFAA7326),
      ),
      'cancelled' => ('Closed', const Color(0xFFE8E8E8), Colors.black54),
      _ => ('Open', const Color(0xFFEE9188), const Color(0xFF9A2E2E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
  late bool _assignmentEnabled = widget.request.assignedTo != null;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Request'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
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
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ColoredBox(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 24),
                children: [
                  _DetailSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCase(request.issueType),
                          style: const TextStyle(
                            color: _requestGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        Text(_longDateLabel(request.createdAt)),
                        const Divider(height: 18),
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          request.description,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: _requestGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 9),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    color: _requestGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_floorLabel(request.floor)}  \u00B7  Near ${request.facilityId}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Container(
                          height: 106,
                          decoration: BoxDecoration(
                            border: Border.all(color: _requestGreen),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: RequestThumbnail(
                            request: request,
                            width: double.infinity,
                            height: 106,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Assign Worker',
                              style: TextStyle(
                                color: _requestGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Switch.adaptive(
                              value: _assignmentEnabled,
                              activeTrackColor: _requestGreen,
                              onChanged: (enabled) => setState(() {
                                _assignmentEnabled = enabled;
                                if (!enabled) _assignedTo = null;
                              }),
                            ),
                          ],
                        ),
                        if (_assignmentEnabled) ...[
                          DropdownButtonFormField<String?>(
                            initialValue:
                                staff.any((user) => user.uid == _assignedTo)
                                ? _assignedTo
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              for (final user in staff)
                                DropdownMenuItem<String?>(
                                  value: user.uid,
                                  child: Text(user.fullName),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _assignedTo = value),
                          ),
                        ],
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
                          style: TextStyle(
                            color: _requestGreen,
                            fontWeight: FontWeight.w700,
                          ),
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
                                  padding: const EdgeInsets.only(right: 7),
                                  child: _StatusOption(
                                    label: _statusLabel(status),
                                    selected: _status == status,
                                    onTap: () =>
                                        setState(() => _status = status),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveChanges(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _requestGreen,
                        shape: const StadiumBorder(),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
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

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _requestGreen : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        height: 31,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    ),
  );
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

String _statusLabel(String status) => switch (status) {
  'in_progress' => 'In Progress',
  'completed' => 'Complete',
  _ => 'Pending',
};

String _titleCase(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

String _floorLabel(int? floor) => switch (floor) {
  1 => 'First Floor',
  2 => 'Second Floor',
  3 => 'Third Floor',
  _ => 'Floor ${floor ?? '?'}',
};

String _longDateLabel(DateTime? date) {
  if (date == null) return 'Date unavailable';
  final local = date.toLocal();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} \u00B7 $hour:$minute $meridiem';
}
