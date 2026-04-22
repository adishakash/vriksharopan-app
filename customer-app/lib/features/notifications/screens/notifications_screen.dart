import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../../../core/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (np.unreadCount > 0)
            TextButton(
              onPressed: () => np.markAllRead(),
              child: const Text('Mark all read',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: np.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : np.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: AppColors.textLight),
                      SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(color: AppColors.textMedium)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => np.load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: np.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _notifTile(np.items[i]),
                  ),
                ),
    );
  }

  Widget _notifTile(NotificationModel n) {
    final iconData = _iconFor(n.type);
    final color = _colorFor(n.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: n.isRead ? AppColors.border : AppColors.primaryLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.w500 : FontWeight.w700,
                          color: AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(n.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n.body,
                  style: const TextStyle(
                      color: AppColors.textMedium, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'tree_update':
        return Icons.park;
      case 'maintenance':
        return Icons.build;
      case 'payment':
        return Icons.payment;
      case 'photo_update':
        return Icons.photo_camera;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'tree_update':
        return AppColors.primary;
      case 'maintenance':
        return AppColors.warning;
      case 'payment':
        return AppColors.info;
      case 'photo_update':
        return AppColors.secondary;
      default:
        return AppColors.textMedium;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inHours < 24) {
      return DateFormat('hh:mm a').format(dt);
    }
    return DateFormat('dd MMM').format(dt);
  }
}
