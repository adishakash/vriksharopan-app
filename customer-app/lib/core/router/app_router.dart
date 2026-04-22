import 'package:flutter/material.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/trees/screens/tree_detail_screen.dart';
import '../../features/trees/screens/trees_map_screen.dart';
import '../../features/gift/screens/gift_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _route(const SplashScreen());
      case '/login':
        return _route(const LoginScreen());
      case '/register':
        return _route(const RegisterScreen());
      case '/home':
        return _route(const HomeScreen());
      case '/tree-detail':
        final treeId = settings.arguments as String;
        return _route(TreeDetailScreen(treeId: treeId));
      case '/trees-map':
        return _route(const TreesMapScreen());
      case '/gift':
        return _route(const GiftScreen());
      case '/subscription':
        return _route(const SubscriptionScreen());
      case '/profile':
        return _route(const ProfileScreen());
      case '/notifications':
        return _route(const NotificationsScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
