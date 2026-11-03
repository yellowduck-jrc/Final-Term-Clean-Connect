import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  final List<Route<dynamic>> _pageRoutes = [];
  final ValueNotifier<int> revision = ValueNotifier(0);

  Route<dynamic>? get _activePageRoute =>
      _pageRoutes.isEmpty ? null : _pageRoutes.last;

  bool shouldShowBackButton(Route<dynamic>? route) =>
      route != null && route == _activePageRoute && _pageRoutes.length > 1;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is! PageRoute<dynamic>) return;

    _pageRoutes.remove(route);
    _pageRoutes.add(route);
    _notifyChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is! PageRoute<dynamic>) return;

    _pageRoutes.remove(route);
    _notifyChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute is PageRoute<dynamic>) {
      final index = _pageRoutes.indexOf(oldRoute);
      if (index >= 0) {
        _pageRoutes.removeAt(index);
        if (newRoute is PageRoute<dynamic>) {
          _pageRoutes.insert(index, newRoute);
        }
      }
    } else if (newRoute is PageRoute<dynamic>) {
      _pageRoutes.add(newRoute);
    }

    _notifyChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is! PageRoute<dynamic>) return;

    _pageRoutes.remove(route);
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

    return ValueListenableBuilder<int>(
      valueListenable: observer.revision,
      builder: (context, _, _) {
        if (!observer.shouldShowBackButton(route)) {
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
