class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final String status;
  final String? profilePhotoUrl;
  final String? referralCode;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.status,
    this.profilePhotoUrl,
    this.referralCode,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      status: json['status']?.toString() ?? 'active',
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      referralCode: json['referral_code']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pinCode: json['pin_code']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'role': role,
        'status': status,
        'profile_photo_url': profilePhotoUrl,
        'referral_code': referralCode,
        'address': address,
        'city': city,
        'state': state,
        'pin_code': pinCode,
        'created_at': createdAt.toIso8601String(),
      };
}
