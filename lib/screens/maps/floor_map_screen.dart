import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';
import '../../models/app_user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/floor_selector.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/staff_bottom_nav.dart';
import 'first_floor.dart';
import 'second_floor.dart';
import 'third_floor.dart';

class FloorMapScreen extends StatefulWidget {
  const FloorMapScreen({super.key});

  @override
  State<FloorMapScreen> createState() => _FloorMapScreenState();
}

class _FloorMapScreenState extends State<FloorMapScreen> {
  int _selectedFloor = 1;

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
          'Clean Connect',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Center(
                          child: Text(
                            '${_floorOrdinal(_selectedFloor)} FLOOR PLAN',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FloorSelector(
                        selectedFloor: _selectedFloor,
                        onChanged: (floor) =>
                            setState(() => _selectedFloor = floor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    children: [
                      switch (_selectedFloor) {
                        1 => const FirstFloorMapScreen(key: ValueKey(1)),
                        2 => const SecondFloorMapScreen(key: ValueKey(2)),
                        3 => const ThirdFloorMapScreen(key: ValueKey(3)),
                        _ => const FirstFloorMapScreen(),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const CustomBottomNav(selectedIndex: 2);
    }

    return FutureBuilder<AppUserModel?>(
      future: UserService().getUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load account navigation: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(height: 50);
        }
        return switch (snapshot.data?.role) {
          'admin' => const AdminBottomNavigationBar(selectedIndex: 2),
          'staff' => const StaffBottomNav(selectedIndex: 2),
          _ => const CustomBottomNav(selectedIndex: 2),
        };
      },
    );
  }

  String _floorOrdinal(int floor) => switch (floor) {
    1 => 'FIRST',
    2 => 'SECOND',
    _ => 'THIRD',
  };
}
