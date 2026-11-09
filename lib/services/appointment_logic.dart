import '../models/appointment.dart';

class AppointmentValidationResult {
  final bool isValid;
  final String? errorMessage;

  const AppointmentValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  static const AppointmentValidationResult success =
      AppointmentValidationResult(isValid: true);
}

class AppointmentLogic {
  static const List<String> monthNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Valida los campos requeridos para agendar una cita médica.
  static AppointmentValidationResult validateAppointment({
    required String doctorName,
    required String specialty,
    required String location,
    required String reason,
    required DateTime date,
    DateTime? now,
  }) {
    final doc = doctorName.trim();
    final spec = specialty.trim();
    final loc = location.trim();
    final rsn = reason.trim();

    if (doc.isEmpty || spec.isEmpty || loc.isEmpty || rsn.isEmpty) {
      return const AppointmentValidationResult(
        isValid: false,
        errorMessage: 'Completa todos los campos de la cita',
      );
    }

    final currentTime = now ?? DateTime.now();
    // No permitir citas con fechas pasadas (con margen de 1 minuto)
    if (date.isBefore(currentTime.subtract(const Duration(minutes: 1)))) {
      return const AppointmentValidationResult(
        isValid: false,
        errorMessage: 'La fecha y hora de la cita no pueden ser en el pasado',
      );
    }

    return AppointmentValidationResult.success;
  }

  /// Ordena cronológicamente una lista de citas por fecha ascendente.
  static List<Appointment> sortChronologically(List<Appointment> appointments) {
    final list = List<Appointment>.from(appointments);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Determina la próxima cita prioritaria a partir de la fecha actual.
  static Appointment? findNextAppointment(
    List<Appointment> appointments, {
    DateTime? now,
  }) {
    if (appointments.isEmpty) return null;
    final currentTime = now ?? DateTime.now();

    final upcoming =
        appointments.where((a) => !a.date.isBefore(currentTime)).toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first;
  }

  /// Formatea la fecha en formato legible en español (ej: "28 sep 2026").
  static String formatDate(DateTime date) {
    if (date.month < 1 || date.month > 12) return '';
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}
