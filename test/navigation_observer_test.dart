import 'package:clean_connect/app/navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_connect/widgets/custom_bottom_nav.dart';
import 'package:clean_connect/widgets/staff_bottom_nav.dart';

void main() {
  testWidgets('back visibility follows forward and return navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appNavigationObserver],
        home: _NavigationTestPage(
          title: 'Home',
          destinations: {
            'Open Requests': (_) => _NavigationTestPage(
              title: 'Requests',
              destinations: {
                'Open Profile': (_) =>
                    const _NavigationTestPage(title: 'Profile'),
                'Open Map': (_) => _NavigationTestPage(
                  title: 'Map',
                  destinations: {
                    'Open Request Details': (_) =>
                        const _NavigationTestPage(title: 'Request Details'),
                  },
                ),
                'Open Request Details': (_) =>
                    const _NavigationTestPage(title: 'Request Details'),
              },
            ),
            'Open Map': (_) => _NavigationTestPage(
              title: 'Map',
              destinations: {
                'Open Request Details': (_) =>
                    const _NavigationTestPage(title: 'Request Details'),
              },
            ),
            'Open Staff Dashboard': (_) => _NavigationTestPage(
              title: 'Staff Dashboard',
              destinations: {
                'Open Requests': (_) => _NavigationTestPage(
                  title: 'Staff Requests',
                  destinations: {
                    'Open Request Details': (_) =>
                        const _NavigationTestPage(title: 'Request Details'),
                  },
                ),
              },
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Open Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Requests'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Requests'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.text('Open Map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Requests'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.text('System Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Open Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Request Details'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Map'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.text('System Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Open Staff Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Request Details'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Staff Requests'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.text('System Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Open Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Request Details'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Map'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('footer tabs follow routes and reuse existing tab pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appNavigationObserver],
        home: const _FooterTestPage(title: 'Home', selectedIndex: 0),
        routes: {
          AppNavigationObserver.mapRoute: (_) =>
              const _FooterTestPage(title: 'Map', selectedIndex: 2),
          AppNavigationObserver.requestsRoute: (_) =>
              const _FooterTestPage(title: 'Requests', selectedIndex: 1),
          AppNavigationObserver.profileRoute: (_) =>
              const _FooterTestPage(title: 'Profile', selectedIndex: 3),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map screen'), findsOneWidget);
    expect(find.text('Selected tab: 2'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Requests screen'), findsOneWidget);
    expect(find.text('Selected tab: 1'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map screen'), findsOneWidget);
    expect(find.text('Selected tab: 2'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Selected tab: 3'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('staff footer switches between all dashboard tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appNavigationObserver],
        home: const _StaffFooterTestPage(title: 'Home', selectedIndex: 0),
        routes: {
          AppNavigationObserver.staffRequestsRoute: (_) =>
              const _StaffFooterTestPage(title: 'Requests', selectedIndex: 1),
          '/map': (_) =>
              const _StaffFooterTestPage(title: 'Map', selectedIndex: 2),
          AppNavigationObserver.profileRoute: (_) =>
              const _StaffFooterTestPage(title: 'Profile', selectedIndex: 3),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Requests page'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map page'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });
}

class _StaffFooterTestPage extends StatelessWidget {
  const _StaffFooterTestPage({
    required this.title,
    required this.selectedIndex,
  });

  final String title;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NavigationBackButton(),
      automaticallyImplyLeading: false,
      title: Text('$title page'),
    ),
    bottomNavigationBar: StaffBottomNav(selectedIndex: selectedIndex),
  );
}

class _FooterTestPage extends StatelessWidget {
  const _FooterTestPage({required this.title, required this.selectedIndex});

  final String title;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NavigationBackButton(),
      automaticallyImplyLeading: false,
      title: Text('$title screen'),
    ),
    body: Builder(
      builder: (context) => Center(
        child: Text(
          'Selected tab: ${appNavigationObserver.selectedTabFor(ModalRoute.of(context), selectedIndex)}',
        ),
      ),
    ),
    bottomNavigationBar: CustomBottomNav(selectedIndex: selectedIndex),
  );
}

class _NavigationTestPage extends StatelessWidget {
  const _NavigationTestPage({
    required this.title,
    this.destinations = const {},
  });

  final String title;
  final Map<String, WidgetBuilder> destinations;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NavigationBackButton(),
      automaticallyImplyLeading: false,
      title: Text(title),
    ),
    body: Column(
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('System Back'),
        ),
        for (final entry in destinations.entries)
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: entry.value)),
            child: Text(entry.key),
          ),
      ],
    ),
  );
}
