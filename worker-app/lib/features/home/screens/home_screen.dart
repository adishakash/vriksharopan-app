import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../orders/screens/orders_list_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../orders/providers/orders_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    OrdersListScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<OrdersProvider>().pendingCount;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: const Icon(Icons.assignment, color: AppColors.primary),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon:
                Icon(Icons.account_balance_wallet, color: AppColors.primary),
            label: 'Earnings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
