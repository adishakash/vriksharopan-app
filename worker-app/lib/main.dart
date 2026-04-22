import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/orders/providers/orders_provider.dart';
import 'features/earnings/providers/earnings_provider.dart';
import 'features/attendance/providers/attendance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();
  await Firebase.initializeApp();
  await NotificationService.init();
  await OfflineSyncService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const WorkerApp(),
    ),
  );
}
