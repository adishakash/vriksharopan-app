import 'package:flutter/material.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/orders/screens/orders_list_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/plant_tree_screen.dart';
import '../../features/earnings/screens/earnings_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _fade(const SplashScreen());
      case '/login':
        return _slide(const LoginScreen());
      case '/home':
        return _fade(const HomeScreen());
      case '/orders':
        return _slide(const OrdersListScreen());
      case '/order-detail':
        final orderId = settings.arguments as String;
        return _slide(OrderDetailScreen(orderId: orderId));
      case '/plant-tree':
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(PlantTreeScreen(
          orderId: args['orderId'] as String,
          treeId: args['treeId'] as String,
        ));
      case '/earnings':
        return _slide(const EarningsScreen());
      case '/attendance':
        return _slide(const AttendanceScreen());
      case '/profile':
        return _slide(const ProfileScreen());
      default:
        return _fade(const SplashScreen());
    }
  }

  static PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  static PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(a),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      );
}
