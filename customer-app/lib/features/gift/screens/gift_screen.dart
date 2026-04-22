import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _occasion = 'birthday';
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await apiService.post(ApiConstants.giftTree, data: {
        'recipient_name': _nameCtrl.text.trim(),
        'recipient_email': _emailCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'occasion': _occasion,
      });
      setState(() => _success = true);
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data['message'] ?? 'Failed to gift tree'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 72, color: AppColors.accent),
                const SizedBox(height: 20),
                const Text('Tree Gifted! 🎉',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 12),
                Text(
                  '${_nameCtrl.text} will receive a notification and monthly updates about their tree.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMedium),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Back to Home',
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gift a Tree')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text('🌳', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gift a Real Tree',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          Text(
                              'A tree will be planted in their name and they\'ll get monthly photo updates.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameCtrl,
                label: "Recipient's Name",
                hint: 'Priya Patel',
                validator: (v) =>
                    (v == null || v.length < 2) ? 'Name required' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _emailCtrl,
                label: "Recipient's Email",
                hint: 'priya@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text('Occasion',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _occasion,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'birthday', child: Text('🎂 Birthday')),
                  DropdownMenuItem(value: 'anniversary', child: Text('💍 Anniversary')),
                  DropdownMenuItem(value: 'wedding', child: Text('💒 Wedding')),
                  DropdownMenuItem(value: 'memorial', child: Text('🕊️ Memorial')),
                  DropdownMenuItem(value: 'other', child: Text('🎁 Other')),
                ],
                onChanged: (v) => setState(() => _occasion = v!),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _messageCtrl,
                label: 'Personal Message (optional)',
                hint: 'Write a heartfelt message...',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Gift a Tree 🌳',
                loading: _loading,
                icon: Icons.card_giftcard,
                onPressed: _submit,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
