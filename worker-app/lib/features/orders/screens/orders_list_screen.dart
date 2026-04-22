import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../providers/orders_provider.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _tabStatuses = ['all', 'pending', 'accepted', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<OrderModel> _filtered(List<OrderModel> all, String tab) {
    if (tab == 'all') return all;
    return all.where((o) => o.status == tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<OrdersProvider>(
        builder: (_, prov, __) {
          if (prov.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return TabBarView(
            controller: _tabs,
            children: _tabStatuses.map((status) {
              final list = _filtered(prov.orders, status);
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text('No $status orders',
                          style: const TextStyle(color: AppColors.textMedium)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => prov.loadOrders(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _OrderCard(order: list[i]),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-detail',
          arguments: order.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(order.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              order.treeNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.speciesName,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMedium),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(order.customerName,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium)),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.locationName,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            if (order.isPending || order.isAccepted) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.currency_rupee,
                    size: 14, color: AppColors.primary),
                const Text(
                  '20 earning',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textLight),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }
}
