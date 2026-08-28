import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import 'offline_banner.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _navigate(context, i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_list_bulleted_rounded),
              selectedIcon: Icon(Icons.view_list_rounded),
              label: 'Jobs',
            ),
          ],
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.jobs)) return 1;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.jobs);
    }
  }
}
