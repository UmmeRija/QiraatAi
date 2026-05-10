import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'animated_bottom_nav.dart';

// Animation only — no logic changed
/*
Visual changes:
1. Replaced the standard NavigationBar with the custom AnimatedBottomNavBar.
2. Maintained all existing routing logic and tab mapping.
*/

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/surahs')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/islamic-guide')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/surahs');
        break;
      case 2:
        context.go('/progress');
        break;
      case 3:
        context.go('/islamic-guide');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    const navBarHeight = 60.0;

    return Scaffold(
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: navBarHeight + bottomInset),
        child: child,
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
