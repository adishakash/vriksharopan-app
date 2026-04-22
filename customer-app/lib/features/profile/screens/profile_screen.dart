import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _mobileCtrl.text = user.mobile;
      _addressCtrl.text = user.address ?? '';
      _cityCtrl.text = user.city ?? '';
      _stateCtrl.text = user.state ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _mobileCtrl, _addressCtrl, _cityCtrl, _stateCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final res = await apiService.put(ApiConstants.profile, data: {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
      });
      final updated = res.data['data']['user'];
      if (mounted) {
        context.read<AuthProvider>().updateUser(
              context.read<AuthProvider>().user!,
            );
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancel' : 'Edit',
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: user.profilePhotoUrl != null
                      ? NetworkImage(user.profilePhotoUrl!)
                      : null,
                  child: user.profilePhotoUrl == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              fontSize: 36,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(user.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ),
          Center(
            child: Text(user.email,
                style: const TextStyle(color: AppColors.textMedium)),
          ),

          const SizedBox(height: 24),

          if (_editing) ...[
            AppTextField(controller: _nameCtrl, label: 'Full Name'),
            const SizedBox(height: 14),
            AppTextField(
                controller: _mobileCtrl,
                label: 'Mobile',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            AppTextField(controller: _addressCtrl, label: 'Address'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: AppTextField(controller: _cityCtrl, label: 'City')),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(controller: _stateCtrl, label: 'State')),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Save Changes', loading: _saving, onPressed: _saveProfile),
          ] else ...[
            _infoCard([
              _row(Icons.phone, 'Mobile', user.mobile),
              _row(Icons.location_on, 'Address',
                  [user.address, user.city, user.state]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', ').isNotEmpty
                      ? [user.address, user.city, user.state]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', ')
                      : 'Not set'),
            ]),
          ],

          // Referral
          if (user.referralCode != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Referral Code',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.referralCode!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () => Share.share(
                          'Use my referral code ${user.referralCode} to plant a tree on Vrisharopan for just ₹99/month! 🌳\nhttps://vrisharopan.in',
                        ),
                      ),
                    ],
                  ),
                  const Text('Share with friends and earn rewards',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          AppButton(
            label: 'Log Out',
            outlined: true,
            color: AppColors.error,
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textLight),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
