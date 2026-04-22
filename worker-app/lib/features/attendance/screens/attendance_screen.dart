import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Consumer<AttendanceProvider>(
        builder: (_, prov, __) {
          final checkedIn = prov.isCheckedIn;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checkedIn
                        ? AppColors.primaryLight
                        : const Color(0xFFFFF3E0),
                  ),
                  child: Icon(
                    checkedIn ? Icons.location_on : Icons.location_off,
                    size: 64,
                    color: checkedIn ? AppColors.primary : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  checkedIn ? 'You are checked in' : 'Not checked in today',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (checkedIn && prov.checkInTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Since ${_fmt(prov.checkInTime!)}',
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textMedium),
                  ),
                ],
                if (prov.error != null) ...[
                  const SizedBox(height: 12),
                  Text(prov.error!,
                      style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 36),
                AppButton(
                  label: checkedIn ? 'Check Out' : 'Check In',
                  icon: checkedIn ? Icons.logout : Icons.login,
                  isLoading: prov.loading,
                  color: checkedIn ? AppColors.error : AppColors.primary,
                  onPressed: () async {
                    bool ok;
                    if (checkedIn) {
                      ok = await prov.checkOut();
                    } else {
                      ok = await prov.checkIn();
                    }
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(checkedIn
                            ? 'Checked out successfully'
                            : 'Checked in successfully'),
                        backgroundColor: AppColors.success,
                      ));
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
