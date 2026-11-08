import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'navigation_observer.dart';
import '../models/app_user_model.dart';
import '../models/request_model.dart';
import '../services/user_service.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_facilities_screen.dart';
import '../screens/admin/manage_requests_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/main_dashboard.dart';
import '../screens/maps/floor_map_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/staff/assigned_requests_screen.dart';
import '../screens/staff/assigned_tasks_screen.dart';
import '../screens/staff/available_requests_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_request_details_screen.dart';
import '../screens/student/my_requests_screen.dart';
import '../screens/student/request_details_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const studentDashboard = '/student';
  static const staffDashboard = AppNavigationObserver.staffDashboardRoute;
  static const adminDashboard = '/admin';
  static const map = AppNavigationObserver.mapRoute;
  static const myRequests = AppNavigationObserver.requestsRoute;
  static const availableRequests = AppNavigationObserver.staffRequestsRoute;
  static const assignedRequests = '/staff/assigned';
  static const assignedTasks = '/staff/tasks';
  static const manageUsers = '/admin/users';
  static const manageRequests = '/admin/requests';
  static const manageFacilities = '/admin/facilities';
  static const profile = AppNavigationObserver.profileRoute;
  static const notifications = '/notifications';
  static const requestDetails = '/request-details';
  static const staffRequestDetails = '/staff/request-details';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    studentDashboard: (_) => const MainDashboard(),
    staffDashboard: (_) =>
        const _RoleOnlyRoute(role: 'staff', child: StaffDashboard()),
    adminDashboard: (_) =>
        const _RoleOnlyRoute(role: 'admin', child: AdminDashboard()),
    map: (_) => const FloorMapScreen(),
    myRequests: (_) => const MyRequestsScreen(),
    availableRequests: (_) =>
        const _RoleOnlyRoute(role: 'staff', child: AvailableRequestsScreen()),
    assignedRequests: (_) =>
        const _RoleOnlyRoute(role: 'staff', child: AssignedRequestsScreen()),
    assignedTasks: (_) =>
        const _RoleOnlyRoute(role: 'staff', child: AssignedTasksScreen()),
    manageUsers: (_) =>
        const _RoleOnlyRoute(role: 'admin', child: ManageUsersScreen()),
    manageRequests: (_) =>
        const _RoleOnlyRoute(role: 'admin', child: ManageRequestsScreen()),
    manageFacilities: (_) =>
        const _RoleOnlyRoute(role: 'admin', child: ManageFacilitiesScreen()),
    profile: (_) => const ProfileScreen(),
    notifications: (_) => const NotificationsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final request = settings.arguments;
    if (settings.name == requestDetails && request is RequestModel) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => RequestDetailsScreen(request: request),
      );
    }

    if (settings.name == staffRequestDetails && request is RequestModel) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _RoleOnlyRoute(
          role: 'staff',
          child: StaffRequestDetailsScreen(request: request),
        ),
      );
    }
    return null;
  }
}

class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (icon: Icons.home_outlined, label: 'Home'),
      (icon: Icons.fact_check_outlined, label: 'Requests'),
      (icon: Icons.map_outlined, label: 'Map'),
      (icon: Icons.person_outline, label: 'Profile'),
    ];
    const routes = [
      AppRoutes.adminDashboard,
      AppRoutes.manageRequests,
      AppRoutes.map,
      AppRoutes.profile,
    ];
    final routeName = ModalRoute.of(context)?.settings.name;
    final currentIndex = switch (routeName) {
      AppRoutes.adminDashboard => 0,
      AppRoutes.manageRequests => 1,
      AppRoutes.map => 2,
      AppRoutes.profile => 3,
      AppRoutes.manageUsers || AppRoutes.manageFacilities => -1,
      _ => selectedIndex == 2 ? -1 : selectedIndex,
    };

    return Container(
      color: const Color(0xFFD9D9D9),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () {
                    if (index != currentIndex) {
                      if (index == 0) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          routes[index],
                          (_) => false,
                        );
                      } else if (index == 3) {
                        Navigator.pushNamed(context, routes[index]);
                      } else {
                        Navigator.pushReplacementNamed(context, routes[index]);
                      }
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index == currentIndex
                              ? const Color(0xFF399849)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          destinations[index].icon,
                          size: 17,
                          color: index == currentIndex
                              ? Colors.white
                              : const Color(0xFF292929),
                        ),
                      ),
                      Text(
                        destinations[index].label,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleOnlyRoute extends StatelessWidget {
  const _RoleOnlyRoute({required this.role, required this.child});

  final String role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return _RouteAccessMessage(
            message: 'Unable to verify your account: ${authSnapshot.error}',
          );
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<AppUserModel?>(
          stream: UserService().watchUser(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _RouteAccessMessage(
                message:
                    'Unable to verify your account: ${profileSnapshot.error}',
              );
            }
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = profileSnapshot.data;
            if (profile?.role == role && profile!.isActive) return child;
            final roleName = role == 'admin' ? 'administrators' : 'staff';
            return _RouteAccessMessage(
              message: 'This page is available to $roleName only.',
            );
          },
        );
      },
    );
  }
}

class _RouteAccessMessage extends StatelessWidget {
  const _RouteAccessMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
