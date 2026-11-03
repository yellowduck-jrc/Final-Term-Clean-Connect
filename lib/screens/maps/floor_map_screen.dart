import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';
import '../../widgets/floor_selector.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${_floorOrdinal(_selectedFloor)} FLOOR PLAN',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: NavigationBackButton(),
                        ),
                      ],
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
      bottomNavigationBar: _MapBottomNavigationBar(
        onTap: (index) {
          if (index == 0) {
            Navigator.maybePop(context);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.myRequests);
          } else if (index == 3) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
      ),
    );
  }

  String _floorOrdinal(int floor) => switch (floor) {
    1 => 'FIRST',
    2 => 'SECOND',
    _ => 'THIRD',
  };
}

class _MapBottomNavigationBar extends StatelessWidget {
  const _MapBottomNavigationBar({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_outlined,
      Icons.fact_check_outlined,
      Icons.map_outlined,
      Icons.person_outline,
    ];
    const labels = ['Home', 'Requests', 'Map', 'Profile'];

    return Container(
      color: const Color(0xFFE0E0E0),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var index = 0; index < icons.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        height: 27,
                        decoration: BoxDecoration(
                          color: index == 2
                              ? const Color(0xFF83D9B3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icons[index], size: 19),
                      ),
                      const SizedBox(height: 2),
                      Text(labels[index], style: const TextStyle(fontSize: 10)),
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
