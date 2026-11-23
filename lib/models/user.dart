import 'user_medical_data.dart';

enum UserRole { admin, doctor, user }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;
  final String? specialty;
  final UserMedicalData medicalData;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.isActive = true,
    this.specialty,
    this.medicalData = const UserMedicalData(),
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawMedical = json['medicalData'];
    final medicalData = rawMedical is Map
        ? UserMedicalData.fromJson(Map<String, dynamic>.from(rawMedical))
        : const UserMedicalData();

    return AppUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      specialty: json['specialty'],
      medicalData: medicalData,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'DOCTOR':
        return UserRole.doctor;
      default:
        return UserRole.user;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role.name.toUpperCase(),
    'profileImage': profileImage,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'specialty': specialty,
    'medicalData': medicalData.toJson(),
  };

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    bool? isActive,
    String? specialty,
    UserMedicalData? medicalData,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      specialty: specialty ?? this.specialty,
      medicalData: medicalData ?? this.medicalData,
    );
  }
}
