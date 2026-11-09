import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/models/appointment.dart';
import 'package:medicontrol/services/appointment_logic.dart';

void main() {
  group('Fase 2: Pruebas Unitarias - AppointmentLogic', () {
    final fixedNow = DateTime(2026, 10, 23, 10, 0);

    // 1. CASO VÁLIDO
    test('Caso Válido: Valida exitosamente una cita con datos completos y fecha futura', () {
      final futureDate = DateTime(2026, 10, 28, 14, 30);

      final result = AppointmentLogic.validateAppointment(
        doctorName: 'Dra. Ana López',
        specialty: 'Cardiología',
        location: 'Clínica del Norte',
        reason: 'Control anual de presión arterial',
        date: futureDate,
        now: fixedNow,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);

      final formatted = AppointmentLogic.formatDate(futureDate);
      expect(formatted, equals('28 oct 2026'));
    });

    // 2. CASO LÍMITE (BOUNDARY CASES)
    test('Caso Límite: Cita programada en el límite temporal actual y ordenamiento por minutos', () {
      // Límite: Fecha exactamente igual a la fecha de referencia actual
      final boundaryDate = DateTime(2026, 10, 23, 10, 0);

      final boundaryResult = AppointmentLogic.validateAppointment(
        doctorName: 'Dr. Carlos Mendoza',
        specialty: 'Urgencias',
        location: 'Pabellón 1',
        reason: 'Consulta inmediata',
        date: boundaryDate,
        now: fixedNow,
      );

      expect(boundaryResult.isValid, isTrue, reason: 'Debe admitir citas en el margen de tiempo presente');

      // Límite: Dos citas con 1 minuto de diferencia deben ordenarse estrictamente por hora
      final citaTemprana = Appointment(
        id: '1',
        doctorName: 'Dr. A',
        specialty: 'Medicina',
        location: 'Sala 1',
        reason: 'Chequeo',
        date: DateTime(2026, 10, 24, 08, 0),
      );
      final citaTardia = Appointment(
        id: '2',
        doctorName: 'Dr. B',
        specialty: 'Medicina',
        location: 'Sala 2',
        reason: 'Chequeo',
        date: DateTime(2026, 10, 24, 08, 1), // 1 minuto después
      );

      final sorted = AppointmentLogic.sortChronologically([citaTardia, citaTemprana]);
      expect(sorted.first.id, equals(1));
      expect(sorted.last.id, equals(2));

      // Límite: findNextAppointment con una cita expirada hace 1 hora y otra futura
      final citaPasada = Appointment(
        id: '3',
        doctorName: 'Dr. Pasado',
        specialty: 'General',
        location: 'Sala 3',
        reason: 'Antiguo',
        date: fixedNow.subtract(const Duration(hours: 1)),
      );

      final next = AppointmentLogic.findNextAppointment([citaPasada, citaTemprana], now: fixedNow);
      expect(next?.id, equals(1), reason: 'Debe descartar la cita vencida y priorizar la futura');
    });

    // 3. CASO INVÁLIDO O DE ERROR
    test('Caso Inválido / Error: Rechaza campos en blanco y fechas en el pasado', () {
      // 3.1. Campos vacíos
      final blankResult = AppointmentLogic.validateAppointment(
        doctorName: '   ',
        specialty: '',
        location: 'Clínica',
        reason: '',
        date: fixedNow.add(const Duration(days: 1)),
        now: fixedNow,
      );

      expect(blankResult.isValid, isFalse);
      expect(blankResult.errorMessage, equals('Completa todos los campos de la cita'));

      // 3.2. Fecha en el pasado
      final pastDate = fixedNow.subtract(const Duration(days: 2));
      final pastResult = AppointmentLogic.validateAppointment(
        doctorName: 'Dr. Pasado',
        specialty: 'Pediatría',
        location: 'Hospital',
        reason: 'Fiebre',
        date: pastDate,
        now: fixedNow,
      );

      expect(pastResult.isValid, isFalse);
      expect(pastResult.errorMessage, equals('La fecha y hora de la cita no pueden ser en el pasado'));

      // 3.3. Formateo de fecha inválida (mes fuera de rango 1-12)
      final invalidMonthDate = DateTime(2026, 13, 1); // Manejo defensivo
      final formattedInvalid = AppointmentLogic.formatDate(invalidMonthDate);
      expect(formattedInvalid, isNotEmpty);
    });
  });
}
