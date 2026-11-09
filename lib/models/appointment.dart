class Appointment {
  final String? id;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String reason;
  final String location;

  const Appointment({
    this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.reason,
    required this.location,
  });
}
