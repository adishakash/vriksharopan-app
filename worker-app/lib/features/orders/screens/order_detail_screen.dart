import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _accepting = false;
  bool _rejecting = false;

  Future<void> _accept(OrderModel order) async {
    setState(() => _accepting = true);
    final ok = await context.read<OrdersProvider>()
        .updateOrderStatus(order.id, 'accepted');
    if (!mounted) return;
    setState(() => _accepting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order accepted!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _reject(OrderModel order) async {
    final confirmed = await _confirmDialog('Reject Order',
        'Are you sure you want to reject this order?');
    if (!confirmed) return;
    setState(() => _rejecting = true);
    final ok = await context.read<OrdersProvider>()
        .updateOrderStatus(order.id, 'rejected');
    if (!mounted) return;
    setState(() => _rejecting = false);
    if (ok) {
      Navigator.pop(context);
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(title,
                      style: const TextStyle(color: AppColors.error))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersProvider>().getOrderById(widget.orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Detail')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(order.treeNumber)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(status: order.status),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Tree Information',
              icon: Icons.forest,
              children: [
                _InfoRow('Tree Number', order.treeNumber),
                _InfoRow('Species', order.speciesName),
                _InfoRow('Location', order.locationName),
                if (order.locationAddress != null)
                  _InfoRow('Address', order.locationAddress!),
                if (order.dueDate != null)
                  _InfoRow('Due Date',
                      DateFormat('dd MMM yyyy').format(order.dueDate!)),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Customer Details',
              icon: Icons.person,
              children: [
                _InfoRow('Name', order.customerName),
                if (order.customerMobile != null)
                  _InfoRow('Mobile', order.customerMobile!),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Your Earning',
              icon: Icons.currency_rupee,
              children: [
                _InfoRow('Planting Fee', '₹20.00'),
                _InfoRow('Per Month', '₹20.00 (while tree stays active)'),
              ],
            ),
            const SizedBox(height: 28),
            if (order.isPending) ...[
              AppButton(
                label: 'Accept Order',
                isLoading: _accepting,
                onPressed: () => _accept(order),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Reject',
                isLoading: _rejecting,
                onPressed: () => _reject(order),
                outlined: true,
                color: AppColors.error,
              ),
            ],
            if (order.isAccepted || order.isInProgress)
              AppButton(
                label: 'Plant Tree → Start',
                icon: Icons.park,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/plant-tree',
                  arguments: {'orderId': order.id, 'treeId': order.treeId},
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'Awaiting your response';
        icon = Icons.pending_outlined;
        break;
      case 'accepted':
        color = AppColors.info;
        label = 'Accepted — Plant the tree';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Completed ✓';
        icon = Icons.task_alt;
        break;
      default:
        color = AppColors.textMedium;
        label = status;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color, fontSize: 15)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ]),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
        ],
      ),
    );
  }
}
