import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/common/app_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  int _treeCount = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    try {
      final res = await apiService.post(
        ApiConstants.createSubscription,
        data: {'tree_count': _treeCount},
      );
      final d = res.data['data'];

      final user = context.read<AuthProvider>().user;
      final options = {
        'key': d['razorpayKeyId'],
        'subscription_id': d['subscriptionId'],
        'name': 'Vrisharopan',
        'description': '$_treeCount Tree${_treeCount > 1 ? 's' : ''} × ₹99/month',
        'prefill': {
          'name': user?.name ?? '',
          'email': user?.email ?? '',
          'contact': user?.mobile ?? '',
        },
        'theme': {'color': '#16A34A'},
      };
      _razorpay.open(options);
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Failed to create subscription');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSuccess(PaymentSuccessResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Your trees will be planted shortly 🌳'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _onError(PaymentFailureResponse res) {
    _showError(res.message ?? 'Payment failed. Please try again.');
  }

  void _onExternalWallet(ExternalWalletResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${res.walletName}')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _treeCount * 99;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How many trees?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Each tree is planted, maintained, and tracked by a local worker.',
                style: TextStyle(color: AppColors.textMedium),
              ),
              const SizedBox(height: 32),

              // Counter
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _counterBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (_treeCount > 1) {
                              setState(() => _treeCount--);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '$_treeCount',
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        _counterBtn(
                          icon: Icons.add,
                          onTap: () {
                            if (_treeCount < 50) {
                              setState(() => _treeCount++);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tree${_treeCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppColors.textMedium, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Price breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _priceRow('$_treeCount tree${_treeCount > 1 ? 's' : ''} × ₹99',
                        '₹$amount/month'),
                    const Divider(height: 20),
                    _priceRow('Monthly total', '₹$amount',
                        isBold: true, color: AppColors.primary),
                    const SizedBox(height: 6),
                    const Text(
                      'Cancel anytime. No long-term commitment.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // What's included
              const Text('What you get:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 8),
              ...[
                'GPS-tagged tree planted by local worker',
                'Monthly photo updates',
                'Tree health monitoring',
                'CO₂ and O₂ impact dashboard',
              ].map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(s,
                            style: const TextStyle(
                                color: AppColors.textMedium, fontSize: 13)),
                      ],
                    ),
                  )),

              const SizedBox(height: 20),
              AppButton(
                label: 'Subscribe – ₹$amount/month',
                loading: _loading,
                icon: Icons.park,
                onPressed: _subscribe,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counterBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textMedium,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontSize: isBold ? 17 : 14,
                color: color ?? AppColors.textDark)),
      ],
    );
  }
}
