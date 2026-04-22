import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _passwordCtrl, _mobileCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pinCtrl, _referralCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      mobile: _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pinCode: _pinCtrl.text.trim(),
      referralCode: _referralCtrl.text.trim().isEmpty
          ? null
          : _referralCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/subscription');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().state == AuthState.loading;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _section('Personal Info'),
              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Arjun Sharma',
                validator: (v) =>
                    (v == null || v.length < 2) ? 'Name required' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'arjun@email.com',
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
              AppTextField(
                controller: _mobileCtrl,
                label: 'Mobile Number',
                hint: '9876543210',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Mobile required';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                    return 'Enter valid 10-digit Indian number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Min 8 chars with upper, lower & number',
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textLight,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Minimum 8 characters';
                  if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
                    return 'Must have uppercase, lowercase and number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _section('Address'),
              AppTextField(
                controller: _addressCtrl,
                label: 'Street Address',
                hint: 'House no., street, area',
                validator: (v) =>
                    (v == null || v.length < 5) ? 'Address required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Mumbai',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _stateCtrl,
                      label: 'State',
                      hint: 'Maharashtra',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _pinCtrl,
                label: 'PIN Code',
                hint: '400001',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || !RegExp(r'^\d{6}$').hasMatch(v)) {
                    return '6-digit PIN code required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _section('Referral (Optional)'),
              AppTextField(
                controller: _referralCtrl,
                label: 'Referral Code',
                hint: 'ABCD1234',
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Create Account & Subscribe',
                loading: loading,
                onPressed: _register,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: TextStyle(color: AppColors.textMedium)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Log in',
                        style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textMedium,
            letterSpacing: 0.5,
          ),
        ),
      );
}
