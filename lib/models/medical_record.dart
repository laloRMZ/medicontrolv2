class MedicalRecord {
  final String? id;
  final String title;
  final String description;
  final List<String> details;

  const MedicalRecord({
    this.id,
    required this.title,
    required this.description,
    required this.details,
  });
}
