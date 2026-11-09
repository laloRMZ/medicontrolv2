import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/emergency_contact.dart';
import '../models/medical_record.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _serverPort = '3000';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:$_serverPort';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_serverPort';
    }
    return 'http://localhost:$_serverPort';
  }

  static Future<UserProfile> fetchProfile() async {
    try {
      final url = '$baseUrl/api/profile';
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout conectando a $url'),
          );
      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile(
        fullName: data['fullName'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        bloodType: data['bloodType'] ?? '',
        allergies: data['allergies'] ?? '',
        address: data['address'] ?? '',
        emergencyContactName: data['emergencyContactName'] ?? '',
      );
    } catch (e) {
      throw Exception('Error en fetchProfile: $e\nURL: $baseUrl/api/profile');
    }
  }

  static Future<List<Doctor>> fetchDoctors() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/doctors'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Error cargando médicos');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return Doctor(
        id: (map['id'] as int?)?.toString(),
        name: map['name'] ?? '',
        specialty: map['specialty'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        clinic: map['clinic'] ?? '',
      );
    }).toList();
  }

  static Future<List<Appointment>> fetchAppointments() async {
    try {
      final url = '$baseUrl/api/appointments';
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout conectando a $url'),
          );
      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as List;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        return Appointment(
          id: (map['id'] as int?)?.toString(),
          doctorName: map['doctorName'] ?? '',
          specialty: map['specialty'] ?? '',
          date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
          reason: map['reason'] ?? '',
          location: map['location'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Error en fetchAppointments: $e\nURL: $baseUrl/api/appointments',
      );
    }
  }

  static Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/emergency-contacts'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Error cargando contactos');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return EmergencyContact(
        id: (map['id'] as int?)?.toString(),
        name: map['name'] ?? '',
        relation: map['relation'] ?? '',
        phone: map['phone'] ?? '',
        notes: map['notes'] ?? '',
      );
    }).toList();
  }

  static Future<List<MedicalRecord>> fetchMedicalRecords() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/medical-records'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Error cargando registros');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final details = (map['details'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      return MedicalRecord(
        id: (map['id'] as int?)?.toString(),
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        details: details,
      );
    }).toList();
  }

  static Future<int> createDoctor(Doctor doctor) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/doctors'),
      headers: headers,
      body: jsonEncode({
        'name': doctor.name,
        'specialty': doctor.specialty,
        'phone': doctor.phone,
        'email': doctor.email,
        'clinic': doctor.clinic,
      }),
    );

    return _createdId(response, 'No se pudo guardar el médico');
  }

  static Future<int> createAppointment(Appointment appointment) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/appointments'),
      headers: headers,
      body: jsonEncode({
        'doctorName': appointment.doctorName,
        'specialty': appointment.specialty,
        'date': appointment.date.toUtc().toIso8601String(),
        'reason': appointment.reason,
        'location': appointment.location,
      }),
    );

    return _createdId(response, 'No se pudo guardar la cita');
  }

  static Future<int> createEmergencyContact(EmergencyContact contact) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/emergency-contacts'),
      headers: headers,
      body: jsonEncode({
        'name': contact.name,
        'relation': contact.relation,
        'phone': contact.phone,
        'notes': contact.notes,
      }),
    );

    return _createdId(response, 'No se pudo guardar el contacto');
  }

  static Future<int> createMedicalRecord(MedicalRecord record) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/medical-records'),
      headers: headers,
      body: jsonEncode({
        'title': record.title,
        'description': record.description,
        'details': record.details,
      }),
    );

    return _createdId(response, 'No se pudo guardar el registro');
  }

  static int _createdId(http.Response response, String errorMessage) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(errorMessage);
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as int;
  }

  static Future<void> deleteDoctor(int id) => _delete('/api/doctors/$id');

  static Future<void> deleteAppointment(int id) =>
      _delete('/api/appointments/$id');

  static Future<void> deleteEmergencyContact(int id) =>
      _delete('/api/emergency-contacts/$id');

  static Future<void> deleteMedicalRecord(int id) =>
      _delete('/api/medical-records/$id');

  static Future<void> _delete(String path) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el registro');
    }
  }
}
