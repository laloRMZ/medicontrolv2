enum UserRole { admin, doctor, user }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
  };
}
