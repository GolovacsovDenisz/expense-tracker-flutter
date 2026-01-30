import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;

        if (index == 0) {
          context.go('/home');
        } else {
          context.go('/dashboard');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.list_alt),
          label: 'Transactions',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline),
          label: 'Dashboard',
        ),
      ],
    );
  }
}
