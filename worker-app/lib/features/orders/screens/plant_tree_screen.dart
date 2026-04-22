import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/orders_provider.dart';

class PlantTreeScreen extends StatefulWidget {
  final String orderId;
  final String treeId;
  const PlantTreeScreen(
      {super.key, required this.orderId, required this.treeId});

  @override
  State<PlantTreeScreen> createState() => _PlantTreeScreenState();
}

class _PlantTreeScreenState extends State<PlantTreeScreen> {
  final _notesCtrl = TextEditingController();
  File? _photo;
  Position? _position;
  bool _fetchingLocation = false;
  bool _uploading = false;
  String? _error;

  String _health = 'excellent'; // excellent|good|fair|poor
  final _healthOptions = ['excellent', 'good', 'fair', 'poor'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied';
          _fetchingLocation = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _position = pos;
        _fetchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not get location';
        _fetchingLocation = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_position == null) {
      setState(() => _error = 'Please capture GPS location first');
      return;
    }
    if (_photo == null) {
      setState(() => _error = 'Please take a photo of the tree');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    final isOnline = await OfflineSyncService.isOnline();

    if (!isOnline) {
      // Queue for later sync
      await StorageService.queueMaintenanceLog({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'tree_id': widget.treeId,
        'type': 'planting',
        'health': _health,
        'notes': _notesCtrl.text,
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'logged_at': DateTime.now().toIso8601String(),
      });
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved offline. Will sync when online.'),
          backgroundColor: AppColors.warning,
        ));
        Navigator.pop(context);
      }
      return;
    }

    try {
      // 1. Geo-tag the tree
      await apiService.post(
        '${ApiConstants.trees}/${widget.treeId}/geo-tag',
        data: {
          'latitude': _position!.latitude,
          'longitude': _position!.longitude,
          'location_accuracy': _position!.accuracy,
        },
      );

      // 2. Upload photo
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(_photo!.path,
            filename: 'tree_${widget.treeId}.jpg'),
        'caption': 'Planting photo',
      });
      await apiService.upload(
          '${ApiConstants.trees}/${widget.treeId}/photos', form);

      // 3. Log maintenance
      await apiService.post(
        '${ApiConstants.trees}/${widget.treeId}/maintenance',
        data: {
          'health_status': _health,
          'notes': _notesCtrl.text.isEmpty ? 'Tree planted' : _notesCtrl.text,
          'maintenance_type': 'planting',
        },
      );

      // 4. Mark order complete
      await context.read<OrdersProvider>()
          .updateOrderStatus(widget.orderId, 'completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tree planted successfully! ₹20 added to earnings.'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed. Check connection.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Tree')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _StepRow(
              steps: const ['GPS', 'Photo', 'Health', 'Complete'],
              current: _position == null
                  ? 0
                  : _photo == null
                      ? 1
                      : 2,
            ),
            const SizedBox(height: 24),

            // GPS
            const _SectionLabel(label: '1. GPS Location', icon: Icons.gps_fixed),
            const SizedBox(height: 8),
            if (_position != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_position!.latitude.toStringAsFixed(5)}, '
                    '${_position!.longitude.toStringAsFixed(5)}\n'
                    'Accuracy: ${_position!.accuracy.toStringAsFixed(1)}m',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDark),
                  ),
                ]),
              )
            else
              AppButton(
                label: 'Capture GPS Location',
                icon: Icons.gps_fixed,
                isLoading: _fetchingLocation,
                onPressed: _getLocation,
              ),

            const SizedBox(height: 20),

            // Photo
            const _SectionLabel(label: '2. Tree Photo', icon: Icons.camera_alt),
            const SizedBox(height: 8),
            if (_photo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_photo!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _photo = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textDark,
                    ),
                  ),
                ),
              ]),

            const SizedBox(height: 20),

            // Health
            const _SectionLabel(
                label: '3. Tree Health', icon: Icons.health_and_safety),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _healthOptions.map((h) {
                final selected = h == _health;
                return ChoiceChip(
                  label: Text(h[0].toUpperCase() + h.substring(1)),
                  selected: selected,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textMedium,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _health = h),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Notes
            const _SectionLabel(
                label: '4. Notes (optional)', icon: Icons.notes),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any observations about the planting site...',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.error)),
                ]),
              ),
            ],

            const SizedBox(height: 28),
            AppButton(
              label: 'Complete Planting',
              icon: Icons.park,
              isLoading: _uploading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textDark)),
    ]);
  }
}

class _StepRow extends StatelessWidget {
  final List<String> steps;
  final int current;
  const _StepRow({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: active || done
                            ? AppColors.primary
                            : AppColors.textLight,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Container(
                  height: 2,
                  width: 16,
                  color: i < current ? AppColors.primary : AppColors.border),
          ]),
        );
      }),
    );
  }
}
