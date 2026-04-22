import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/tree_model.dart';

enum TreesState { initial, loading, loaded, error }

class TreesProvider extends ChangeNotifier {
  TreesState _state = TreesState.initial;
  List<TreeModel> _trees = [];
  TreeModel? _selectedTree;
  List<dynamic> _photos = [];
  List<dynamic> _maintenanceLogs = [];
  String? _error;

  int _page = 1;
  bool _hasMore = true;

  TreesState get state => _state;
  List<TreeModel> get trees => _trees;
  TreeModel? get selectedTree => _selectedTree;
  List<dynamic> get photos => _photos;
  List<dynamic> get maintenanceLogs => _maintenanceLogs;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadTrees({bool refresh = false}) async {
    if (_state == TreesState.loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _trees = [];
    }
    if (!_hasMore) return;

    _state = TreesState.loading;
    notifyListeners();

    try {
      final res = await apiService.get(ApiConstants.trees,
          params: {'page': _page, 'limit': 20});
      final d = res.data['data'];
      final items = (d['trees'] as List? ?? [])
          .map((t) => TreeModel.fromJson(t as Map))
          .toList();

      _trees.addAll(items);
      _hasMore = (d['pagination']?['hasMore'] ?? false);
      _page++;
      _state = TreesState.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load trees';
      _state = TreesState.error;
    }
    notifyListeners();
  }

  Future<void> loadTreeDetail(String treeId) async {
    _state = TreesState.loading;
    notifyListeners();
    try {
      final res = await apiService.get('${ApiConstants.trees}/$treeId');
      final d = res.data['data'];
      _selectedTree = TreeModel.fromJson(d['tree'] as Map);
      _photos = d['photos'] ?? [];
      _maintenanceLogs = d['maintenanceLogs'] ?? [];
      _state = TreesState.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load tree details';
      _state = TreesState.error;
    }
    notifyListeners();
  }
}
