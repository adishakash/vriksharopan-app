import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AttendanceProvider extends ChangeNotifier {
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  bool _loading = false;
  String? _error;

  bool get isCheckedIn => _isCheckedIn;
  DateTime? get checkInTime => _checkInTime;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> checkIn() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = await _getPos();
      await apiService.post(ApiConstants.checkIn, data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      _isCheckedIn = true;
      _checkInTime = DateTime.now();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Check-in failed. Try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = await _getPos();
      await apiService.post(ApiConstants.checkOut, data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      _isCheckedIn = false;
      _checkInTime = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Check-out failed. Try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Position> _getPos() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
