import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/trees_provider.dart';

class TreeDetailScreen extends StatefulWidget {
  final String treeId;
  const TreeDetailScreen({super.key, required this.treeId});

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreesProvider>().loadTreeDetail(widget.treeId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TreesProvider>();
    final tree = tp.selectedTree;

    if (tp.state == TreesState.loading && tree == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (tree == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tree not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: tree.coverPhotoUrl != null
                  ? GestureDetector(
                      onTap: () => _openPhotoViewer(context, [tree.coverPhotoUrl!], 0),
                      child: CachedNetworkImage(
                        imageUrl: tree.coverPhotoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.park,
                          size: 80, color: AppColors.primary),
                    ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMedium,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Photos'),
                Tab(text: 'Timeline'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _OverviewTab(tree: tree),
            _PhotosTab(photos: tp.photos, onTap: (i) {
              final urls = tp.photos
                  .map((p) => p['photo_url']?.toString() ?? '')
                  .toList();
              _openPhotoViewer(context, urls, i);
            }),
            _TimelineTab(logs: tp.maintenanceLogs),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(BuildContext context, List<String> urls, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PhotoViewGallery.builder(
          itemCount: urls.length,
          initialIndex: index,
          builder: (_, i) => PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(urls[i]),
            minScale: PhotoViewComputedScale.contained,
          ),
        ),
      );
    }));
  }
}

class _OverviewTab extends StatelessWidget {
  final dynamic tree;
  const _OverviewTab({required this.tree});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard([
          _row('Tree ID', tree.treeNumber),
          _row('Species', tree.speciesName ?? 'Not assigned'),
          _row('Status', tree.status),
          _row('Health', tree.health),
          if (tree.locationName != null) _row('Location', tree.locationName!),
          if (tree.plantedAt != null)
            _row('Planted', DateFormat('dd MMM yyyy').format(tree.plantedAt!)),
        ]),
        if (tree.isGeoTagged) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Open in Google Maps'),
            onPressed: () {
              final url =
                  'https://maps.google.com/?q=${tree.latitude},${tree.longitude}';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
          ),
        ],
        if (tree.dedicatedTo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dedicated to',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(tree.dedicatedTo!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (tree.dedicatedMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(tree.dedicatedMessage!,
                      style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        const Text('Environmental Impact (Annual)',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Row(
          children: [
            _impactChip('CO₂', '21.77 kg', AppColors.info),
            const SizedBox(width: 10),
            _impactChip('O₂', '100 kg', AppColors.success),
            const SizedBox(width: 10),
            _impactChip('Water', '450 L', AppColors.secondary),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _impactChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final List<dynamic> photos;
  final void Function(int) onTap;
  const _PhotosTab({required this.photos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No photos yet. Your worker will upload soon.',
                style: TextStyle(color: AppColors.textMedium),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final url = photos[i]['photo_url']?.toString() ?? '';
        return GestureDetector(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.border),
            ),
          ),
        );
      },
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<dynamic> logs;
  const _TimelineTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No maintenance logs yet.',
            style: TextStyle(color: AppColors.textMedium)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final log = logs[i];
        final isFirst = i == 0;
        final isLast = i == logs.length - 1;
        final date = DateTime.tryParse(log['log_date']?.toString() ?? '');

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 16,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          beforeLineStyle: const LineStyle(color: AppColors.primaryLight, thickness: 2),
          afterLineStyle: const LineStyle(color: AppColors.primaryLight, thickness: 2),
          endChild: Container(
            margin: const EdgeInsets.only(left: 12, bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                const SizedBox(height: 4),
                Text(
                  log['notes']?.toString() ?? 'Maintenance done',
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                ),
                if (log['health_after'] != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Health: ',
                          style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                      Text(log['health_after'].toString(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
