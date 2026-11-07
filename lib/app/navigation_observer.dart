import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  static const requestsRoute = '/requests';
  static const mapRoute = '/map';
  static const profileRoute = '/profile';
  static const studentRoute = '/student';
  static const staffDashboardRoute = '/staff';
  static const staffRequestsRoute = '/staff/available';

  final ValueNotifier<int> revision = ValueNotifier(0);

  bool shouldShowBackButton(Route<dynamic>? route, bool canPop) {
    if (route?.isCurrent != true || !canPop) return false;
    return !{
      studentRoute,
      requestsRoute,
      mapRoute,
      profileRoute,
      staffDashboardRoute,
      staffRequestsRoute,
    }.contains(route?.settings.name);
  }

  int selectedTabFor(Route<dynamic>? route, int fallback) {
    if (route?.isCurrent != true) return fallback;
    return switch (route?.settings.name) {
      requestsRoute => 1,
      mapRoute => 2,
      profileRoute => 3,
      staffDashboardRoute => 0,
      staffRequestsRoute => 1,
      _ => fallback,
    };
  }

  void navigateToTab(BuildContext context, int index) {
    final navigator = Navigator.of(context);
    if (index == 0) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    final targetName = switch (index) {
      1 => requestsRoute,
      2 => mapRoute,
      3 => profileRoute,
      _ => null,
    };
    if (targetName == null) return;

    if (ModalRoute.of(context)?.settings.name == targetName) return;
    navigator.pushNamedAndRemoveUntil(targetName, (route) => route.isFirst);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notifyChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notifyChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notifyChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notifyChanged();
  }

  void _notifyChanged() {
    revision.value++;
  }
}

class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final observer = appNavigationObserver;
    final navigator = Navigator.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: observer.revision,
      builder: (context, _, _) {
        if (!observer.shouldShowBackButton(route, navigator.canPop())) {
          return const SizedBox.shrink();
        }

        return IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        );
      },
    );
  }
}

final appNavigationObserver = AppNavigationObserver();
