import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/tree_model.dart';

class DashboardData {
  final int totalTrees;
  final int activeTrees;
  final double totalCo2;
  final double totalOxygen;
  final List<TreeModel> trees;
  final String? referralCode;
  final int referralCount;

  DashboardData({
    required this.totalTrees,
    required this.activeTrees,
    required this.totalCo2,
    required this.totalOxygen,
    required this.trees,
    this.referralCode,
    required this.referralCount,
  });
}

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardState _state = DashboardState.initial;
  DashboardData? _data;
  String? _error;

  DashboardState get state => _state;
  DashboardData? get data => _data;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _state = DashboardState.loading;
    notifyListeners();

    try {
      final res = await apiService.get(ApiConstants.dashboard);
      final d = res.data['data'];

      final trees = (d['trees'] as List? ?? [])
          .map((t) => TreeModel.fromJson(t as Map))
          .toList();

      _data = DashboardData(
        totalTrees: d['total_trees'] ?? 0,
        activeTrees: d['active_trees'] ?? 0,
        totalCo2: double.tryParse(d['total_co2_absorbed']?.toString() ?? '0') ?? 0,
        totalOxygen:
            double.tryParse(d['total_oxygen_generated']?.toString() ?? '0') ?? 0,
        trees: trees,
        referralCode: d['referral_code']?.toString(),
        referralCount: d['referral_count'] ?? 0,
      );
      _state = DashboardState.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load dashboard';
      _state = DashboardState.error;
    }
    notifyListeners();
  }
}
