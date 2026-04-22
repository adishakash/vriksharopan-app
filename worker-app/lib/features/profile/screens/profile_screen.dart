import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final worker = context.read<AuthProvider>().worker;
    if (worker != null) {
      _nameCtrl.text = worker.name;
      _mobileCtrl.text = worker.mobile;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await apiService.put('/workers/profile', data: {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
      });
      if (mounted) {
        final auth = context.read<AuthProvider>();
        auth.updateWorker(
          auth.worker!.copyWith(
            name: _nameCtrl.text.trim(),
            mobile: _mobileCtrl.text.trim(),
          ),
        );
        setState(() {
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = context.watch<AuthProvider>().worker;
    if (worker == null) return const SizedBox();

    final initials = worker.name.isNotEmpty
        ? worker.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : 'W';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(worker.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            Text(worker.email,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMedium)),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: worker.status == 'active'
                    ? AppColors.primaryLight
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                worker.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: worker.status == 'active'
                      ? AppColors.primary
                      : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_editing) ...[
              AppTextField(
                label: 'Full Name',
                hint: 'Your name',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Mobile',
                hint: '10-digit mobile number',
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: AppButton(
                    label: 'Save',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    outlined: true,
                    onPressed: () => setState(() => _editing = false),
                  ),
                ),
              ]),
            ] else ...[
              _InfoTile(Icons.phone, 'Mobile', worker.mobile),
              if (worker.workerCode != null)
                _InfoTile(Icons.badge, 'Worker Code', worker.workerCode!),
              if (worker.totalTreesPlanted != null)
                _InfoTile(Icons.forest, 'Trees Planted',
                    '${worker.totalTreesPlanted}'),
              if (worker.totalEarned != null)
                _InfoTile(Icons.currency_rupee, 'Total Earned',
                    '₹${worker.totalEarned!.toStringAsFixed(0)}'),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Logout',
              icon: Icons.logout,
              outlined: true,
              color: AppColors.error,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ],
        ),
      ]),
    );
  }
}
