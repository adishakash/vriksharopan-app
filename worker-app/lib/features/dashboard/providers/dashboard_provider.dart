import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class DashboardData {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalEarned;
  final double thisMonthEarnings;
  final int treesPlantedThisMonth;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  const DashboardData({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalEarned,
    required this.thisMonthEarnings,
    required this.treesPlantedThisMonth,
    required this.isCheckedIn,
    this.checkedInAt,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        totalOrders: j['total_orders'] ?? 0,
        pendingOrders: j['pending_orders'] ?? 0,
        completedOrders: j['completed_orders'] ?? 0,
        totalEarned: (j['total_earned'] as num?)?.toDouble() ?? 0.0,
        thisMonthEarnings:
            (j['this_month_earnings'] as num?)?.toDouble() ?? 0.0,
        treesPlantedThisMonth: j['trees_planted_this_month'] ?? 0,
        isCheckedIn: j['is_checked_in'] ?? false,
        checkedInAt: j['checked_in_at'] != null
            ? DateTime.parse(j['checked_in_at'])
            : null,
      );
}

class DashboardProvider extends ChangeNotifier {
  DashboardData? _data;
  bool _loading = false;

  DashboardData? get data => _data;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await apiService.get(ApiConstants.dashboard);
      _data = DashboardData.fromJson(res.data['data']);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
