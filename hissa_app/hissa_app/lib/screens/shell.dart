import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/strings.dart';
import '../app/theme.dart';

/// Bottom navigation shell. Each tab keeps its own navigation stack, so
/// pushing a stock detail and coming back does not reset the others.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: context.pageBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cs.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            // Tapping the active tab again pops it back to its root.
            initialLocation: i == navigationShell.currentIndex,
          ),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.t('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined),
              selectedIcon: const Icon(Icons.trending_up_rounded),
              label: s.t('nav_invest'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: s.t('nav_wallet'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.workspace_premium_outlined),
              selectedIcon: const Icon(Icons.workspace_premium_rounded),
              label: s.t('nav_plans'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: s.t('nav_settings'),
            ),
          ],
        ),
      ),
    );
  }
}
