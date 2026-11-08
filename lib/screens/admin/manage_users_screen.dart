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
  Widget build(BuildContext context) => const CircleAvatar(
    radius: 25,
    backgroundColor: Color(0xFF36984D),
    child: Icon(Icons.person, color: Color(0xFFD9D9D9), size: 34),
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
  late final bool _isActive = widget.user.isActive;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
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

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 20),
            children: [
              _UserPanel(
                child: Row(
                  children: [
                    const _UserAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RolePill(role: user.role),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _UserPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        'User Activity',
                        style: TextStyle(
                          color: Color(0xFF2FA455),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityMetric(
                            value: '${activity.length}',
                            label: isStaff
                                ? 'Requests Assigned'
                                : 'Requests Made',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActivityMetric(
                            value: '${completed.length}',
                            label: 'Completed Requests',
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
                            label: 'Cancelled Requests',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActivityMetric(
                            value: _averageCompletionTime(
                              completed,
                              isStaff: isStaff,
                            ),
                            label: 'Avg. completion time',
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
                          color: Color(0xFF2FA455),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
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
              const SizedBox(height: 14),
              _UserPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        'Change User Type',
                        style: TextStyle(
                          color: Color(0xFF2FA455),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final role in const ['student', 'staff', 'admin'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _RoleOption(
                                label: '${role[0].toUpperCase()}${role.substring(1)}',
                                selected: _role == role,
                                onTap: () => setState(() => _role = role),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: _isSaving ? null : () => _saveChanges(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF36984D),
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
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 3),
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
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFB0CBB5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF36984D),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2FA455),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFF4E9A6) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 32,
        child: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
      ),
    ),
  );
}

class _UserRequestTile extends StatelessWidget {
  const _UserRequestTile({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'completed' => const Color(0xFFC8E7D0),
      'in_progress' => const Color(0xFFF4E9A6),
      _ => const Color(0xFFE8A39A),
    };
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFB0CBB5),
        borderRadius: BorderRadius.circular(10),
      ),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          Text(
            '${request.id} - ${request.issueType}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 21,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.facilityId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  request.status.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF93813C)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  if (completedCount == 0) return 'â€”';

  final average = totalMinutes ~/ completedCount;
  return average >= 60 ? '${average ~/ 60}h' : '${average}min';
}
