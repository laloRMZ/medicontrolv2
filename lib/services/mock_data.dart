import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/emergency_contact.dart';
import '../models/medical_record.dart';
import '../models/user_profile.dart';

class MockData {
  static const UserProfile user = UserProfile(
    fullName: 'Eduardo Rodríguez',
    email: 'eduardo@medicontrol.com',
    phone: '+57 320 123 4567',
    bloodType: 'O+',
    allergies: 'Penicilina, mariscos',
    address: 'Calle 45 #12-34, Medellín',
    emergencyContactName: 'María Rodríguez',
  );

  static const List<MedicalRecord> medicalRecords = [
    MedicalRecord(
      title: 'Antecedentes',
      description: 'Historial médico general y observaciones importantes.',
      details: [
        'Hipertensión controlada',
        'No presenta alergias graves además de las reportadas',
        'Última revisión: mayo 2026',
      ],
    ),
    MedicalRecord(
      title: 'Resumen actual',
      description: 'Información relevante para la atención médica.',
      details: [
        'Tipo de sangre: O+',
        'Medicamentos actuales: Vitamina D y Aspirina',
        'Hábitos: ejercicio moderado tres veces por semana',
      ],
    ),
  ];

  static final List<Appointment> appointments = [
    Appointment(
      doctorName: 'Dra. Ana López',
      specialty: 'Cardiología',
      date: DateTime(2026, 9, 28, 10, 30),
      reason: 'Control de presión arterial',
      location: 'Clínica del Norte',
    ),
    Appointment(
      doctorName: 'Dr. Camilo Pérez',
      specialty: 'Medicina general',
      date: DateTime(2026, 10, 5, 9, 0),
      reason: 'Chequeo general',
      location: 'Consultorio central',
    ),
  ];

  static const List<Doctor> doctors = [
    Doctor(
      name: 'Dra. Ana López',
      specialty: 'Cardiología',
      phone: '+57 300 111 2222',
      email: 'ana.lopez@clinica.com',
      clinic: 'Clínica del Norte',
    ),
    Doctor(
      name: 'Dr. Camilo Pérez',
      specialty: 'Medicina general',
      phone: '+57 301 333 4444',
      email: 'camilo.perez@consultorio.com',
      clinic: 'Consultorio central',
    ),
    Doctor(
      name: 'Dra. Laura Gómez',
      specialty: 'Endocrinología',
      phone: '+57 302 555 6666',
      email: 'laura.gomez@centromedico.com',
      clinic: 'Centro Médico Vida',
    ),
  ];

  static const List<EmergencyContact> emergencyContacts = [
    EmergencyContact(
      name: 'María Rodríguez',
      relation: 'Madre',
      phone: '+57 310 987 6543',
      notes: 'Contacto principal en caso de emergencia.',
    ),
    EmergencyContact(
      name: 'Luis Rodríguez',
      relation: 'Hermano',
      phone: '+57 311 222 3344',
      notes: 'Disponibilidad en la tarde.',
    ),
  ];
}
