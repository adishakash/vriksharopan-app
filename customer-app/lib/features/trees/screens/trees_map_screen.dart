import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/trees_provider.dart';

class TreesMapScreen extends StatefulWidget {
  const TreesMapScreen({super.key});

  @override
  State<TreesMapScreen> createState() => _TreesMapScreenState();
}

class _TreesMapScreenState extends State<TreesMapScreen> {
  late GoogleMapController _mapCtrl;
  final Set<Marker> _markers = {};

  static const LatLng _india = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final trees = context.read<TreesProvider>().trees;
    setState(() {
      _markers.clear();
      for (final tree in trees) {
        if (!tree.isGeoTagged) continue;
        _markers.add(
          Marker(
            markerId: MarkerId(tree.id),
            position: LatLng(tree.latitude!, tree.longitude!),
            infoWindow: InfoWindow(
              title: tree.treeNumber,
              snippet: tree.speciesName ?? tree.status,
              onTap: () =>
                  Navigator.pushNamed(context, '/tree-detail', arguments: tree.id),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trees Map')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: _india, zoom: 5),
        markers: _markers,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        onMapCreated: (ctrl) {
          _mapCtrl = ctrl;
          if (_markers.isNotEmpty) {
            _mapCtrl.animateCamera(
              CameraUpdate.newLatLng(_markers.first.position),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.my_location, color: Colors.white),
        label: const Text('My Location',
            style: TextStyle(color: Colors.white)),
        onPressed: () {},
      ),
    );
  }
}
