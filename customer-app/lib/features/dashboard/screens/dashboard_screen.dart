import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/models/tree_model.dart';
import '../../../widgets/common/app_button.dart';

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
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final dp = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<DashboardProvider>().loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your trees are growing 🌱',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            if (dp.state == DashboardState.loading && dp.data == null)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (dp.state == DashboardState.error && dp.data == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(dp.error ?? 'Error loading dashboard'),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Retry',
                        onPressed: () => dp.loadDashboard(),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Impact Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Environmental Impact',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('Total Trees', '${dp.data?.totalTrees ?? 0}',
                              Icons.park, AppColors.primary),
                          const SizedBox(width: 12),
                          _statCard('Active', '${dp.data?.activeTrees ?? 0}',
                              Icons.eco, AppColors.secondary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            'CO₂ Absorbed',
                            '${(dp.data?.totalCo2 ?? 0).toStringAsFixed(1)} kg/yr',
                            Icons.air,
                            AppColors.info,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            'O₂ Generated',
                            '${(dp.data?.totalOxygen ?? 0).toStringAsFixed(0)} kg/yr',
                            Icons.yard,
                            AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          context,
                          icon: Icons.add_circle_outline,
                          label: 'Plant More',
                          sub: '₹99/tree/month',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/subscription'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionCard(
                          context,
                          icon: Icons.card_giftcard,
                          label: 'Gift a Tree',
                          sub: 'For someone special',
                          color: AppColors.accent,
                          onTap: () => Navigator.pushNamed(context, '/gift'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Trees
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Trees',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),

              if (dp.data?.trees.isEmpty ?? true)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.park_outlined, size: 48, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          const Text('Your trees are being planted.',
                              style: TextStyle(color: AppColors.textMedium)),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Plant Your First Tree',
                            onPressed: () => Navigator.pushNamed(context, '/subscription'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final tree = dp.data!.trees[i];
                      return _treeListTile(context, tree);
                    },
                    childCount: dp.data?.trees.length ?? 0,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMedium),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(sub,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _treeListTile(BuildContext context, TreeModel tree) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tree-detail', arguments: tree.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: tree.coverPhotoUrl != null
                  ? Image.network(tree.coverPhotoUrl!,
                      width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.park, color: AppColors.primary, size: 30),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tree.treeNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  if (tree.speciesName != null)
                    Text(tree.speciesName!,
                        style: const TextStyle(
                            color: AppColors.textMedium, fontSize: 13)),
                  if (tree.locationName != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text(tree.locationName!,
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
            _healthBadge(tree.health),
          ],
        ),
      ),
    );
  }

  Widget _healthBadge(String health) {
    final colors = {
      'excellent': AppColors.healthExcellent,
      'good': AppColors.healthGood,
      'fair': AppColors.healthFair,
      'poor': AppColors.healthPoor,
    };
    final color = colors[health] ?? AppColors.healthGood;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(health,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}


