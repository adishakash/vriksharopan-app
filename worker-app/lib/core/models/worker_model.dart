class WorkerModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final String status;
  final String? profilePhotoUrl;
  final String? workerCode;
  final double? totalEarned;
  final int? totalTreesPlanted;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.status,
    this.profilePhotoUrl,
    this.workerCode,
    this.totalEarned,
    this.totalTreesPlanted,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        mobile: j['mobile'] ?? '',
        role: j['role'] ?? 'worker',
        status: j['status'] ?? 'pending',
        profilePhotoUrl: j['profile_photo_url'],
        workerCode: j['worker_code'],
        totalEarned: (j['total_earned'] as num?)?.toDouble(),
        totalTreesPlanted: j['total_trees_planted'] as int?,
      );

  WorkerModel copyWith({String? name, String? mobile}) => WorkerModel(
        id: id,
        name: name ?? this.name,
        email: email,
        mobile: mobile ?? this.mobile,
        role: role,
        status: status,
        profilePhotoUrl: profilePhotoUrl,
        workerCode: workerCode,
        totalEarned: totalEarned,
        totalTreesPlanted: totalTreesPlanted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'role': role,
        'status': status,
        'profile_photo_url': profilePhotoUrl,
        'worker_code': workerCode,
        'total_earned': totalEarned,
        'total_trees_planted': totalTreesPlanted,
      };
}
