import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../../../core/models/earning_model.dart';
import '../../../core/constants/api_constants.dart';

class EarningsSummary {
  final double total;
  final double thisMonth;
  final double pending;
  final double paid;

  const EarningsSummary({
    required this.total,
    required this.thisMonth,
    required this.pending,
    required this.paid,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> j) => EarningsSummary(
        total: (j['total'] as num?)?.toDouble() ?? 0.0,
        thisMonth: (j['this_month'] as num?)?.toDouble() ?? 0.0,
        pending: (j['pending'] as num?)?.toDouble() ?? 0.0,
        paid: (j['paid'] as num?)?.toDouble() ?? 0.0,
      );
}

class EarningsProvider extends ChangeNotifier {
  EarningsSummary? _summary;
  List<EarningModel> _history = [];
  bool _loading = false;

  EarningsSummary? get summary => _summary;
  List<EarningModel> get history => _history;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await apiService.get(ApiConstants.earnings);
      final data = res.data['data'];
      _summary = EarningsSummary.fromJson(data['summary'] ?? {});
      _history = ((data['history'] as List?) ?? [])
          .map((j) => EarningModel.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('Earnings load error: $e');
    }
    _loading = false;
    notifyListeners();
  }
}
