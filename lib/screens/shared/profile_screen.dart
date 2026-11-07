import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';
import '../../models/app_user_model.dart';
import '../../services/auth_service.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/staff_bottom_nav.dart';

const _headerColor = Color(0xFF242735);
const _accentColor = Color(0xFF20A879);
const _detailBackground = Color(0xFFD9D9D9);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<AppUserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _profileFuture = user == null
        ? Future.value(null)
        : UserService().getUser(user.uid);
  }

  Future<void> _editProfile(
    BuildContext context,
    User authUser,
    String fullName,
    String email,
  ) async {
    final result = await showDialog<_ProfileEditResult>(
      context: context,
      builder: (_) => _EditProfileDialog(fullName: fullName, email: email),
    );
    if (result != null && mounted) {
      setState(() {
        _profileFuture = UserService().getUser(authUser.uid);
      });
      if (result.emailVerificationSent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A verification link was sent to ${result.newEmail}. '
              'Your email will change after you confirm it.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _headerColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: FutureBuilder<AppUserModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final isStaff = snapshot.data?.role == 'staff';
            return AppBar(
              leading: isStaff
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NavigationBackButton(),
                        IconButton(
                          tooltip: 'Sign out',
                          onPressed: () => _signOut(context),
                          icon: const Icon(Icons.logout, size: 19),
                        ),
                      ],
                    )
                  : const NavigationBackButton(),
              leadingWidth: isStaff ? 96 : null,
              automaticallyImplyLeading: false,
              backgroundColor: _headerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: Text(
                isStaff ? 'My Profile' : 'Clean Connect',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            );
          },
        ),
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: Colors.white,
          child: authUser == null
              ? const Center(child: Text('Sign in to view your profile.'))
              : FutureBuilder<AppUserModel?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load your profile: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final profile = snapshot.data;
                    final fullName =
                        profile?.fullName ?? authUser.displayName ?? 'User';
                    final email = authUser.email ?? profile?.email ?? '';
                    final role = profile?.role ?? 'student';
                    final isStaff = role == 'staff';

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isStaff ? 16 : 28,
                        24,
                        20,
                      ),
                      children: [
                        _ProfileIdentity(
                          name: fullName,
                          role: role,
                          photoUrl: authUser.photoURL,
                        ),
                        SizedBox(height: isStaff ? 12 : 20),
                        if (isStaff) ...[
                          _StaffTaskStats(uid: authUser.uid),
                          const SizedBox(height: 16),
                        ] else if (role == 'student') ...[
                          _RequestStats(uid: authUser.uid),
                          const SizedBox(height: 26),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _editProfile(
                                context,
                                authUser,
                                fullName,
                                email,
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF8A2541),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isStaff) ...[
                          _PersonalInfoRow(
                            icon: Icons.person,
                            label: 'Full Name:',
                            value: fullName,
                            compact: true,
                          ),
                          const _PersonalInfoRow(
                            icon: Icons.calendar_month,
                            label: 'Date of Birth:',
                            value: 'Not provided',
                            compact: true,
                          ),
                          _PersonalInfoRow(
                            icon: Icons.email,
                            label: 'Email:',
                            value: email,
                            compact: true,
                          ),
                          const _PersonalInfoRow(
                            icon: Icons.phone,
                            label: 'Contact:',
                            value: 'Not provided',
                            compact: true,
                          ),
                          const _PersonalInfoRow(
                            icon: Icons.location_on,
                            label: 'Address:',
                            value: 'Not provided',
                            compact: true,
                          ),
                        ] else ...[
                          _PersonalInfoRow(
                            icon: Icons.person,
                            label: 'Full Name:',
                            value: fullName,
                          ),
                          _PersonalInfoRow(
                            icon: Icons.calendar_month,
                            label: 'Email:',
                            value: email,
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (!isStaff)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _signOut(context),
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Sign out'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
      bottomNavigationBar: authUser == null
          ? const CustomBottomNav(selectedIndex: 3)
          : FutureBuilder<AppUserModel?>(
              future: _profileFuture,
              builder: (context, snapshot) => snapshot.data?.role == 'staff'
                  ? const StaffBottomNav(selectedIndex: 3)
                  : const CustomBottomNav(selectedIndex: 3),
            ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to sign out: $error')));
      }
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.fullName, required this.email});

  final String fullName;
  final String email;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.emailVerificationSent,
    required this.newEmail,
  });

  final bool emailVerificationSent;
  final String newEmail;
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  var _saving = false;
  String? _errorMessage;

  bool get _emailChanged => _emailController.text.trim() != widget.email.trim();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _emailController.addListener(_emailChangedListener);
  }

  void _emailChangedListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final emailVerificationSent = await AuthService().updateProfile(
        fullName: _nameController.text,
        email: _emailController.text,
        currentPassword: _emailChanged ? _passwordController.text : null,
      );
      if (mounted) {
        Navigator.of(context).pop(
          _ProfileEditResult(
            emailVerificationSent: emailVerificationSent,
            newEmail: _emailController.text.trim(),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to update your profile: $error';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit Profile'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name.'
                  : null,
            ),
            TextFormField(
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: AuthService.validateEmail,
            ),
            if (_emailChanged)
              TextFormField(
                controller: _passwordController,
                enabled: !_saving,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (value) =>
                    _emailChanged && (value == null || value.isEmpty)
                    ? 'Enter your current password to change your email.'
                    : null,
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.name,
    required this.role,
    required this.photoUrl,
  });

  final String name;
  final String role;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE34563), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl == null || imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFF2F2F2),
                    child: Icon(
                      Icons.person,
                      size: 42,
                      color: Color(0xFF9A9A9A),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFF2F2F2),
                      child: Icon(
                        Icons.person,
                        size: 42,
                        color: Color(0xFF9A9A9A),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF0BE81),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role == 'staff'
                ? 'Cleaning staff'
                : role[0].toUpperCase() + role.substring(1),
            style: const TextStyle(
              color: Color(0xFFB36B12),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffTaskStats extends StatelessWidget {
  const _StaffTaskStats({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RequestService().watchAssignedRequests(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load task statistics: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 146,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final assigned = snapshot.data!;
        final completed = assigned
            .where((request) => request.status == 'completed')
            .length;
        final completionRate = assigned.isEmpty
            ? 0
            : (completed * 100 / assigned.length).round();

        return Container(
          height: 146,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFBFE4D9),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StaffTaskStat(
                  icon: Icons.check_circle,
                  value: '$completed',
                  label: 'Task Completed',
                ),
              ),
              Container(width: 1, color: const Color(0xFF399849)),
              Expanded(
                child: _StaffTaskStat(
                  icon: Icons.bar_chart,
                  value: '$completionRate%',
                  label: 'Completion Rate',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffTaskStat extends StatelessWidget {
  const _StaffTaskStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 40, color: const Color(0xFF399849)),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF292D3C),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF4A5568), fontSize: 11),
      ),
    ],
  );
}

class _RequestStats extends StatelessWidget {
  const _RequestStats({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RequestService().watchRequestsByReporter(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load request statistics: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final now = DateTime.now();
        final today = snapshot.data!.where((request) {
          final createdAt = request.createdAt;
          return createdAt != null &&
              createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        });
        final requests = today.toList();
        int count(Set<String> statuses) => requests
            .where(
              (request) => statuses.contains(
                request.status.toLowerCase().replaceAll(' ', '_'),
              ),
            )
            .length;

        return Row(
          children: [
            Expanded(
              child: _RequestStatCard(
                count: count({'pending'}),
                label: 'Pending Request',
                color: const Color(0xFFE99436),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RequestStatCard(
                count: count({'in_progress', 'accepted'}),
                label: 'On Progress',
                color: const Color(0xFF6FA4D9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RequestStatCard(
                count: count({'completed'}),
                label: 'Finished Request',
                color: const Color(0xFFEE857F),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RequestStatCard extends StatelessWidget {
  const _RequestStatCard({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 114,
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: color, width: 1.4),
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x35000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 9),
        ),
        const Text(
          'for today',
          style: TextStyle(color: Color(0xFF777777), fontSize: 9),
        ),
      ],
    ),
  );
}

class _PersonalInfoRow extends StatelessWidget {
  const _PersonalInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _detailBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: _accentColor),
        SizedBox(width: compact ? 12 : 14),
        SizedBox(
          width: compact ? 84 : 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: compact ? 10 : 12),
          ),
        ),
      ],
    ),
  );
}
