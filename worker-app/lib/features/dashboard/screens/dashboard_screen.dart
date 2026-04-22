import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../../attendance/providers/attendance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<DashboardProvider, AttendanceProvider>(
        builder: (_, dash, att, __) {
          final d = dash.data;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Good morning! 👋',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              d == null
                                  ? '...'
                                  : '₹${d.thisMonthEarnings.toStringAsFixed(0)} this month',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (dash.loading && d == null)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Attendance Card
                      _AttendanceCard(provider: att),
                      const SizedBox(height: 16),

                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatCard(
                            label: 'Pending Orders',
                            value: '${d?.pendingOrders ?? 0}',
                            icon: Icons.pending_actions,
                            color: AppColors.warning,
                          ),
                          _StatCard(
                            label: 'Trees Planted',
                            value: '${d?.treesPlantedThisMonth ?? 0}',
                            icon: Icons.forest,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            label: 'Completed',
                            value: '${d?.completedOrders ?? 0}',
                            icon: Icons.task_alt,
                            color: AppColors.success,
                          ),
                          _StatCard(
                            label: 'Total Earned',
                            value:
                                '₹${(d?.totalEarned ?? 0).toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            color: AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Actions
                      const Text('Quick Actions',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _QuickAction(
                          icon: Icons.assignment,
                          label: 'My Orders',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/orders'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _QuickAction(
                          icon: Icons.account_balance_wallet,
                          label: 'Earnings',
                          color: AppColors.info,
                          onTap: () => Navigator.pushNamed(context, '/earnings'),
                        )),
                      ]),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceProvider provider;
  const _AttendanceCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final checkedIn = provider.isCheckedIn;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: checkedIn
              ? [const Color(0xFF065F46), AppColors.primary]
              : [const Color(0xFF1E3A5F), AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(
          checkedIn ? Icons.location_on : Icons.location_off,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                checkedIn ? 'You are checked in' : 'Not checked in',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              if (checkedIn && provider.checkInTime != null)
                Text(
                  'Since ${_fmt(provider.checkInTime!)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor:
                checkedIn ? AppColors.primary : AppColors.info,
            minimumSize: const Size(80, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () =>
              Navigator.pushNamed(context, '/attendance'),
          child: Text(checkedIn ? 'Check Out' : 'Check In'),
        ),
      ]),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

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
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}
