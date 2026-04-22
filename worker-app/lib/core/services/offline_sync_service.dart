import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class OfflineSyncService {
  static final Connectivity _connectivity = Connectivity();

  static Future<void> init() async {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingLogs();
      }
    });
  }

  static Future<void> syncPendingLogs() async {
    final queue = StorageService.getMaintenanceQueue();
    if (queue.isEmpty) return;

    final token = StorageService.getAccessToken();
    if (token == null) return;

    try {
      await apiService.post(ApiConstants.syncOffline, data: {
        'maintenanceLogs': List<Map>.from(queue),
      });
      await StorageService.clearMaintenanceQueue();
      debugPrint('Synced ${queue.length} offline logs');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  static Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
