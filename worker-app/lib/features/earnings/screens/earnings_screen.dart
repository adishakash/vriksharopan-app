import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/earning_model.dart';
import '../providers/earnings_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<EarningsProvider>(
        builder: (_, prov, __) {
          if (prov.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final s = prov.summary;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => prov.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SummaryCard(
                      label: 'Total Earned',
                      value: '₹${s?.total.toStringAsFixed(0) ?? '0'}',
                      color: AppColors.primary,
                      icon: Icons.currency_rupee,
                    ),
                    _SummaryCard(
                      label: 'This Month',
                      value:
                          '₹${s?.thisMonth.toStringAsFixed(0) ?? '0'}',
                      color: AppColors.info,
                      icon: Icons.calendar_month,
                    ),
                    _SummaryCard(
                      label: 'Paid',
                      value:
                          '₹${s?.paid.toStringAsFixed(0) ?? '0'}',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                    _SummaryCard(
                      label: 'Pending',
                      value:
                          '₹${s?.pending.toStringAsFixed(0) ?? '0'}',
                      color: AppColors.warning,
                      icon: Icons.hourglass_bottom,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Earning History',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark)),
                const SizedBox(height: 10),
                if (prov.history.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No earnings yet.',
                          style: TextStyle(color: AppColors.textMedium)),
                    ),
                  )
                else
                  ...prov.history.map((e) => _EarningTile(earning: e)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  final EarningModel earning;
  const _EarningTile({required this.earning});

  @override
  Widget build(BuildContext context) {
    final isPaid = earning.status == 'paid';
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
          child: const Icon(Icons.park, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(earning.treeNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              Text(
                earning.type[0].toUpperCase() + earning.type.substring(1),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${earning.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.primaryLight
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? AppColors.primary : AppColors.warning),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
