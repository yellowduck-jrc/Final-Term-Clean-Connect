import 'package:flutter/material.dart';

import '../app/app_routes.dart';

class StaffBottomNav extends StatelessWidget {
  const StaffBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (icon: Icons.home_outlined, label: 'Home'),
      (icon: Icons.cleaning_services_outlined, label: 'Tasks'),
      (icon: Icons.assignment_outlined, label: 'Requests'),
      (icon: Icons.person_outline, label: 'Profile'),
    ];

    return Container(
      color: const Color(0xFFE0E0E0),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => _navigate(context, index),
                  mouseCursor: SystemMouseCursors.click,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index == selectedIndex
                              ? const Color(0xFF399849)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          destinations[index].icon,
                          size: 20,
                          color: index == selectedIndex
                              ? Colors.white
                              : const Color(0xFF292929),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destinations[index].label,
                        style: const TextStyle(fontSize: 10),
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

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;
    if (index == 0) {
      Navigator.of(context).popUntil(
        (route) =>
            route.settings.name == AppRoutes.staffDashboard || route.isFirst,
      );
      return;
    }

    final targetRoute = switch (index) {
      1 => AppRoutes.assignedTasks,
      2 => AppRoutes.availableRequests,
      3 => AppRoutes.profile,
      _ => null,
    };
    if (targetRoute == null ||
        ModalRoute.of(context)?.settings.name == targetRoute) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      targetRoute,
      (route) =>
          route.settings.name == AppRoutes.staffDashboard || route.isFirst,
    );
  }
}
