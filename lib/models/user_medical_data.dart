class UserMedicalData {
  final String bloodType;
  final String allergies;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String notes;

  const UserMedicalData({
    this.bloodType = '',
    this.allergies = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.notes = '',
  });

  factory UserMedicalData.fromJson(Map<String, dynamic> json) {
    return UserMedicalData(
      bloodType: json['bloodType'] ?? '',
      allergies: json['allergies'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bloodType': bloodType,
    'allergies': allergies,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'notes': notes,
  };

  bool get isEmpty =>
      bloodType.isEmpty &&
      allergies.isEmpty &&
      emergencyContactName.isEmpty &&
      emergencyContactPhone.isEmpty &&
      notes.isEmpty;
}
