import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/trees/providers/trees_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive local DB
  await Hive.initFlutter();
  await StorageService.init();

  // Firebase
  await Firebase.initializeApp();
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TreesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: const VrisharopanApp(),
    ),
  );
}
