import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';

import '../../models/app_user_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = UserService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Manage Users',
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
      body: StreamBuilder<List<AppUserModel>>(
        stream: users.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load users: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No user accounts found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Material(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => _UserProfileScreen(user: user),
                    ),
                  ),
                  child: SizedBox(
                    height: 57,
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const _UserListAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.chevron_right, size: 18),
                            _RolePill(role: user.role),
                          ],
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 2),
    );
  }
}

class _UserListAvatar extends StatelessWidget {
  const _UserListAvatar();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
    radius: 16,
    backgroundColor: Color(0xFF399849),
    child: Icon(Icons.person, color: Color(0xFFD9D9D9), size: 22),
  );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0xFF70A6D4),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'admin' => const Color(0xFFFFEBC8),
      'staff' => const Color(0xFFD9F6F8),
      _ => const Color(0xFFF2F2C9),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        role.isEmpty
            ? 'Unknown'
            : '${role[0].toUpperCase()}${role.substring(1)}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

class _UserProfileScreen extends StatefulWidget {
  const _UserProfileScreen({required this.user});

  final AppUserModel user;

  @override
  State<_UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<_UserProfileScreen> {
  late String _role = widget.user.role;
  late bool _isActive = widget.user.isActive;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('User Profile'),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: RequestService().watchRequestsForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load user activity: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userRequests = snapshot.data!;
          final isStaff = user.role == 'staff';
          final activity = userRequests
              .where(
                (request) => isStaff
                    ? request.assignedTo == user.uid
                    : request.reportedBy == user.uid,
              )
              .toList();
          final completed = activity
              .where((request) => request.status == 'completed')
              .toList();
          final cancelled = activity
              .where((request) => request.status == 'cancelled')
              .length;
          final recent = userRequests
              .where((request) {
                final createdAt = request.createdAt;
                final now = DateTime.now();
                return createdAt != null &&
                    createdAt.year == now.year &&
                    createdAt.month == now.month;
              })
              .take(3)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            children: [
              _UserPanel(
                child: Row(
                  children: [
                    const _UserAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          _RolePill(role: user.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _UserPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        'User Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityMetric(
                            value: '${activity.length}',
                            label: isStaff
                                ? 'Requests Assigned\nto user'
                                : 'Requests Submitted\nby user',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActivityMetric(
                            value: '${completed.length}',
                            label: 'Requests Completed',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityMetric(
                            value: '$cancelled',
                            label: 'Requests Cancelled',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActivityMetric(
                            value: _averageCompletionTime(
                              completed,
                              isStaff: isStaff,
                            ),
                            label: isStaff
                                ? 'Average staff time\nto complete a request'
                                : 'Average time\nto resolve a request',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _UserPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: Text(
                        'Recent Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text('from this month'),
                    ),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No recent requests.'),
                      )
                    else
                      for (final request in recent)
                        _UserRequestTile(request: request),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _UserPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        'Change User Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final role in const ['student', 'staff', 'admin'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  '${role[0].toUpperCase()}${role.substring(1)}',
                                ),
                                selected: _role == role,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _role = role),
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFFFFEBC8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text('Active account'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
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
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 2),
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final users = UserService();
      await users.updateAccountAccess(
        uid: widget.user.uid,
        role: _role,
        isActive: _isActive,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update account: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _UserPanel extends StatelessWidget {
  const _UserPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFB0B0B0),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _UserRequestTile extends StatelessWidget {
  const _UserRequestTile({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 5),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFB0B0B0),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.description,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        Text(
          '${request.id} · ${request.issueType}',
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                request.facilityId,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            Text(
              request.status.replaceAll('_', ' '),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

String _averageCompletionTime(
  List<RequestModel> completed, {
  required bool isStaff,
}) {
  var totalMinutes = 0;
  var completedCount = 0;
  for (final request in completed) {
    final startedAt = isStaff ? request.acceptedAt : request.createdAt;
    final completedAt = request.completedAt;
    if (startedAt == null || completedAt == null) continue;

    final minutes = completedAt.difference(startedAt).inMinutes;
    if (minutes < 0) continue;

    totalMinutes += minutes;
    completedCount++;
  }
  if (completedCount == 0) return '—';

  final average = totalMinutes ~/ completedCount;
  return average >= 60 ? '${average ~/ 60}h' : '${average}min';
}
