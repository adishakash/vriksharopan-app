import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _loading = false;
  int _unreadCount = 0;

  List<NotificationModel> get items => _items;
  bool get loading => _loading;
  int get unreadCount => _unreadCount;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await apiService.get(ApiConstants.notifications);
      final list = res.data['data']['notifications'] as List? ?? [];
      _items = list.map((n) => NotificationModel.fromJson(n as Map)).toList();
      _unreadCount = _items.where((n) => !n.isRead).length;
    } on DioException catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await apiService.put(ApiConstants.markNotificationsRead, data: {'all': true});
      _items = _items.map((n) => NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
