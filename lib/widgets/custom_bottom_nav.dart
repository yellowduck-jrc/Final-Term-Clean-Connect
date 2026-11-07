import 'package:flutter/material.dart';

import '../app/navigation_observer.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    this.selectedColor = const Color(0xFF83D9B3),
  });

  final int selectedIndex;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_outlined,
      Icons.fact_check_outlined,
      Icons.map_outlined,
      Icons.person_outline,
    ];
    const labels = ['Home', 'Requests', 'Map', 'Profile'];
    final route = ModalRoute.of(context);
    final observer = appNavigationObserver;

    return Container(
      color: const Color(0xFFE0E0E0),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<int>(
          valueListenable: observer.revision,
          builder: (context, _, _) {
            final currentIndex = observer.selectedTabFor(route, selectedIndex);
            return Row(
              children: List.generate(icons.length, (index) {
                final selected = index == currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => observer.navigateToTab(context, index),
                    mouseCursor: SystemMouseCursors.click,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 45,
                          height: 27,
                          decoration: BoxDecoration(
                            color: selected
                                ? selectedColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icons[index], size: 19),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[index],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
