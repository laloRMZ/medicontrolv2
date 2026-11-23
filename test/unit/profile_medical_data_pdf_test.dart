import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/models/user.dart';
import 'package:medicontrol/models/user_medical_data.dart';
import 'package:medicontrol/services/profile_pdf_service.dart';

void main() {
  group('AppUser medicalData persistence & PDF generation', () {
    test('AppUser.fromJson and toJson preserve UserMedicalData', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'fullName': 'Ana López',
        'email': 'ana@example.com',
        'phone': '5551234567',
        'role': 'USER',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'medicalData': {
          'bloodType': 'O+',
          'allergies': 'Penicilina',
          'emergencyContactName': 'Carlos López',
          'emergencyContactPhone': '5559876543',
          'notes': 'Asma leve',
        },
      });

      expect(user.medicalData.bloodType, 'O+');
      expect(user.medicalData.allergies, 'Penicilina');
      expect(user.medicalData.emergencyContactName, 'Carlos López');
      expect(user.medicalData.emergencyContactPhone, '5559876543');
      expect(user.medicalData.notes, 'Asma leve');

      final json = user.toJson();
      final roundTrip = AppUser.fromJson(json);
      expect(roundTrip.medicalData.toJson(), user.medicalData.toJson());
    });

    test('AppUser.fromJson defaults to empty UserMedicalData when missing', () {
      final user = AppUser.fromJson({
        'id': 'u2',
        'fullName': 'Luis Pérez',
        'email': 'luis@example.com',
        'phone': '',
        'role': 'USER',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(user.medicalData.isEmpty, isTrue);
    });

    test('ProfilePdfService generates valid PDF bytes for medical profile',
        () async {
      final user = AppUser(
        id: 'u1',
        fullName: 'Ana López',
        email: 'ana@example.com',
        phone: '5551234567',
        role: UserRole.user,
        createdAt: DateTime(2026, 1, 1),
        medicalData: const UserMedicalData(
          bloodType: 'A+',
          allergies: 'Polen, Penicilina',
          emergencyContactName: 'Carlos López',
          emergencyContactPhone: '5559876543',
          notes: 'Uso de inhalador',
        ),
      );

      final bytes = await ProfilePdfService.buildMedicalProfilePdf(
        user,
        useGoogleFonts: false,
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('ProfilePdfService handles empty medical data without throwing',
        () async {
      final user = AppUser(
        id: 'u2',
        fullName: 'Luis Pérez',
        email: 'luis@example.com',
        phone: '',
        role: UserRole.user,
        createdAt: DateTime(2026, 1, 1),
      );

      final bytes = await ProfilePdfService.buildMedicalProfilePdf(
        user,
        useGoogleFonts: false,
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
