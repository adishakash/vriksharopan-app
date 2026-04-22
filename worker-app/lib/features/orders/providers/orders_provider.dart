import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../../../core/models/order_model.dart';
import '../../../core/constants/api_constants.dart';

class OrdersProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _loading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount =>
      _orders.where((o) => o.isPending || o.isAccepted || o.isInProgress).length;

  Future<void> loadOrders({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await apiService.get(ApiConstants.orders,
          params: status != null ? {'status': status} : null);
      final list = (res.data['data'] as List? ?? []);
      _orders = list.map((j) => OrderModel.fromJson(j)).toList();
    } catch (e) {
      _error = 'Failed to load orders';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status,
      {String? notes}) async {
    try {
      await apiService.put('${ApiConstants.orders}/$orderId/status',
          data: {'status': status, if (notes != null) 'notes': notes});
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        // Re-load to get fresh data
        await loadOrders();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
