import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/models/user.dart';
import 'package:medicontrol/services/admin_service.dart';

void main() {
  group('AppUser admin fields', () {
    test('defaults isActive to true and parses specialty', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'fullName': 'Dra. Ana Pérez',
        'email': 'ana@medicontrol.com',
        'phone': '5551234567',
        'role': 'DOCTOR',
        'specialty': 'Cardiología',
      });

      expect(user.role, UserRole.doctor);
      expect(user.isActive, isTrue);
      expect(user.specialty, 'Cardiología');

      final suspended = user.copyWith(isActive: false);
      expect(suspended.isActive, isFalse);
      expect(suspended.toJson()['isActive'], isFalse);
      expect(suspended.toJson()['specialty'], 'Cardiología');
    });
  });

  group('AdminService.buildReportCsv', () {
    test('generates CSV with all sections and escapes quotes', () {
      final report = AdminReportData(
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 23),
        totalUsers: 10,
        activeUsers: 9,
        suspendedUsers: 1,
        patientsCount: 7,
        doctorsCount: 2,
        adminsCount: 1,
        newUsersInPeriod: 3,
        newDoctorsInPeriod: 1,
        usersWithoutMedicalData: 2,
        appointmentsInPeriod: 5,
        appointmentsBySpecialty: {'Cardiología': 3, 'Pediatría "A"': 2},
        appointmentsByDoctor: {'Dra. Ana': 5},
        totalTicketsInPeriod: 4,
        openTickets: 1,
        inProgressTickets: 1,
        resolvedTickets: 2,
        recentUsers: const [],
      );

      final csv = AdminService.buildReportCsv(report);

      expect(csv, contains('Seccion,Indicador,Valor'));
      expect(csv, contains('Usuarios,Total,10'));
      expect(csv, contains('Usuarios,Suspendidos,1'));
      expect(csv, contains('Citas,Total en periodo,5'));
      expect(csv, contains('Citas por especialidad,"Pediatría ""A""",2'));
      expect(csv, contains('Soporte,Resueltos,2'));
    });
  });
}
