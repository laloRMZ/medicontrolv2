import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/models/appointment.dart';
import 'package:medicontrol/models/user_medical_data.dart';
import 'package:medicontrol/widgets/medical_summary_card.dart';
import 'package:medicontrol/widgets/next_appointment_widget.dart';
import 'package:medicontrol/widgets/quick_actions_grid.dart';
import 'package:medicontrol/widgets/user_avatar.dart';

void main() {
  group('Dashboard reusable widgets', () {
    testWidgets('MedicalSummaryCard shows prompt when empty and triggers edit',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalSummaryCard(
              medicalData: const UserMedicalData(),
              onEditPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Completa tu perfil médico'), findsOneWidget);
      await tester.tap(find.text('Completar ahora'));
      expect(tapped, isTrue);
    });

    testWidgets('MedicalSummaryCard shows medical fields when populated',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MedicalSummaryCard(
                medicalData: UserMedicalData(
                  bloodType: 'O+',
                  allergies: 'Penicilina',
                  emergencyContactName: 'Carlos López',
                  emergencyContactPhone: '5559876543',
                  notes: 'Asma leve',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tu Información Médica'), findsOneWidget);
      expect(find.text('O+'), findsOneWidget);
      expect(find.text('Penicilina'), findsOneWidget);
      expect(find.text('Asma leve'), findsOneWidget);
      expect(find.text('Carlos López\n5559876543'), findsOneWidget);
    });

    testWidgets('NextAppointmentWidget renders empty and populated states',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NextAppointmentWidget(appointment: null),
          ),
        ),
      );
      expect(find.text('Sin citas próximas'), findsOneWidget);

      final appointment = Appointment(
        id: 'a1',
        doctorName: 'Dra. Sofía Ramírez',
        specialty: 'Cardiología',
        date: DateTime(2026, 12, 10, 14, 30),
        reason: 'Chequeo',
        location: 'Consultorio 3',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextAppointmentWidget(appointment: appointment),
          ),
        ),
      );

      expect(find.text('Próxima Cita'), findsOneWidget);
      expect(find.text('Dra. Sofía Ramírez'), findsOneWidget);
      expect(find.text('Cardiología'), findsOneWidget);
      expect(find.text('10/12/2026 • 14:30'), findsOneWidget);
    });

    testWidgets('QuickActionsGrid renders items and handles tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsGrid(
              actions: [
                QuickActionItem(
                  icon: Icons.edit,
                  label: 'Editar Perfil',
                  color: Colors.blue,
                  onTap: () => tapped = true,
                ),
                QuickActionItem(
                  icon: Icons.picture_as_pdf,
                  label: 'Perfil en PDF',
                  color: Colors.indigo,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.text('Perfil en PDF'), findsOneWidget);

      await tester.tap(find.text('Editar Perfil'));
      expect(tapped, isTrue);
    });

    testWidgets('UserAvatar shows initial fallback and decodes base64 image',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              profileImage: null,
              fullName: 'María García',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
      await tester.tap(find.byType(UserAvatar));
      expect(tapped, isTrue);

      // 1x1 transparent PNG in base64
      const validPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      final dataUri = 'data:image/png;base64,$validPngBase64';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              profileImage: dataUri,
              fullName: 'María García',
            ),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<MemoryImage>());
      expect(
        (avatar.backgroundImage as MemoryImage).bytes,
        equals(base64Decode(validPngBase64)),
      );
      expect(find.text('M'), findsNothing);
    });
  });
}
