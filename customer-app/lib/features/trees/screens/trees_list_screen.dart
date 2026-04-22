import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/trees_provider.dart';
import '../../../core/models/tree_model.dart';

class TreesListScreen extends StatefulWidget {
  const TreesListScreen({super.key});

  @override
  State<TreesListScreen> createState() => _TreesListScreenState();
}

class _TreesListScreenState extends State<TreesListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreesProvider>().loadTrees(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<TreesProvider>().loadTrees();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TreesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.pushNamed(context, '/trees-map'),
            tooltip: 'View on map',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => tp.loadTrees(refresh: true),
        child: tp.trees.isEmpty && tp.state == TreesState.loading
            ? _buildShimmer()
            : tp.trees.isEmpty
                ? _buildEmpty(context)
                : GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: tp.trees.length + (tp.hasMore ? 2 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= tp.trees.length) return _shimmerCard();
                      return _treeCard(context, tp.trees[i]);
                    },
                  ),
      ),
    );
  }

  Widget _treeCard(BuildContext context, TreeModel tree) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/tree-detail', arguments: tree.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: tree.coverPhotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: tree.coverPhotoUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _shimmerBox(120),
                      errorWidget: (_, __, ___) => _placeholderPhoto(),
                    )
                  : _placeholderPhoto(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tree.treeNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (tree.speciesName != null)
                    Text(
                      tree.speciesName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMedium),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusDot(tree.status),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tree.status,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMedium),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderPhoto() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.primaryLight,
      child: const Icon(Icons.park, color: AppColors.primary, size: 40),
    );
  }

  Widget _statusDot(String status) {
    final color = switch (status) {
      'planted' || 'growing' || 'matured' => AppColors.success,
      'pending' => AppColors.warning,
      _ => AppColors.textLight,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.park_outlined, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('No trees yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Plant your first tree for just ₹99/month',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMedium)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              child: const Text('Plant a Tree'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(height: height, color: Colors.white),
    );
  }
}
