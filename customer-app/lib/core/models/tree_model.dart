class TreeModel {
  final String id;
  final String treeNumber;
  final String? speciesName;
  final String status;
  final String health;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? coverPhotoUrl;
  final String? dedicatedTo;
  final String? dedicatedMessage;
  final DateTime? plantedAt;
  final DateTime createdAt;

  TreeModel({
    required this.id,
    required this.treeNumber,
    this.speciesName,
    required this.status,
    required this.health,
    this.locationName,
    this.latitude,
    this.longitude,
    this.coverPhotoUrl,
    this.dedicatedTo,
    this.dedicatedMessage,
    this.plantedAt,
    required this.createdAt,
  });

  factory TreeModel.fromJson(Map<dynamic, dynamic> json) {
    double? lat, lng;
    if (json['latitude'] != null) lat = double.tryParse(json['latitude'].toString());
    if (json['longitude'] != null) lng = double.tryParse(json['longitude'].toString());

    return TreeModel(
      id: json['id']?.toString() ?? '',
      treeNumber: json['tree_number']?.toString() ?? '',
      speciesName: json['species_name']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      health: json['health']?.toString() ?? 'good',
      locationName: json['location_name']?.toString(),
      latitude: lat,
      longitude: lng,
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      dedicatedTo: json['dedicated_to']?.toString(),
      dedicatedMessage: json['dedicated_message']?.toString(),
      plantedAt: json['planted_at'] != null
          ? DateTime.tryParse(json['planted_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isGeoTagged => latitude != null && longitude != null;
}
