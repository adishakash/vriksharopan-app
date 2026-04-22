class OrderModel {
  final String id;
  final String treeId;
  final String treeNumber;
  final String speciesName;
  final String customerName;
  final String? customerMobile;
  final String locationName;
  final String? locationAddress;
  final String status; // pending | accepted | in_progress | completed | rejected
  final String? notes;
  final double? assignedLat;
  final double? assignedLng;
  final DateTime? dueDate;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.treeId,
    required this.treeNumber,
    required this.speciesName,
    required this.customerName,
    this.customerMobile,
    required this.locationName,
    this.locationAddress,
    required this.status,
    this.notes,
    this.assignedLat,
    this.assignedLng,
    this.dueDate,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'] ?? '',
        treeId: j['tree_id'] ?? '',
        treeNumber: j['tree_number'] ?? '',
        speciesName: j['species_name'] ?? 'Unknown Species',
        customerName: j['customer_name'] ?? 'Customer',
        customerMobile: j['customer_mobile'],
        locationName: j['location_name'] ?? 'Location TBD',
        locationAddress: j['location_address'],
        status: j['status'] ?? 'pending',
        notes: j['notes'],
        assignedLat: (j['assigned_lat'] as num?)?.toDouble(),
        assignedLng: (j['assigned_lng'] as num?)?.toDouble(),
        dueDate:
            j['due_date'] != null ? DateTime.parse(j['due_date']) : null,
        createdAt: DateTime.parse(
            j['created_at'] ?? DateTime.now().toIso8601String()),
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
}
