import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/appointment.dart';
import '../models/emergency_contact.dart';
import '../models/medical_record.dart';
import '../models/doctor.dart';

class UserDataService {
  static final _auth = fb.FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static String? get _userId => _auth.currentUser?.uid;

  // CITAS - Obtener citas del usuario
  static Future<List<Appointment>> getUserAppointments() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('appointments')
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .where((doc) => !doc.id.startsWith('_'))
          .map((doc) {
        final data = doc.data();
        return Appointment(
          id: doc.id,
          doctorName: data['doctorName'] ?? '',
          specialty: data['specialty'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reason: data['reason'] ?? '',
          location: data['location'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // CITAS - Agregar cita
  static Future<bool> addAppointment(Appointment appointment) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('appointments')
          .add({
        'doctorName': appointment.doctorName,
        'specialty': appointment.specialty,
        'date': Timestamp.fromDate(appointment.date),
        'reason': appointment.reason,
        'location': appointment.location,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // CITAS - Eliminar cita
  static Future<bool> deleteAppointment(String appointmentId) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  // CONTACTOS DE EMERGENCIA - Obtener
  static Future<List<EmergencyContact>> getUserEmergencyContacts() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('emergency_contacts')
          .get();

      return snapshot.docs
          .where((doc) => !doc.id.startsWith('_'))
          .map((doc) {
        final data = doc.data();
        return EmergencyContact(
          id: doc.id,
          name: data['name'] ?? '',
          relation: data['relation'] ?? '',
          phone: data['phone'] ?? '',
          notes: data['notes'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // CONTACTOS DE EMERGENCIA - Agregar
  static Future<bool> addEmergencyContact(EmergencyContact contact) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('emergency_contacts')
          .add({
        'name': contact.name,
        'relation': contact.relation,
        'phone': contact.phone,
        'notes': contact.notes,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // CONTACTOS DE EMERGENCIA - Eliminar
  static Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  // REGISTROS MÉDICOS - Obtener
  static Future<List<MedicalRecord>> getUserMedicalRecords() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('medical_records')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .where((doc) => !doc.id.startsWith('_'))
          .map((doc) {
        final data = doc.data();
        final details = (data['details'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        return MedicalRecord(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          details: details,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // REGISTROS MÉDICOS - Agregar
  static Future<bool> addMedicalRecord(MedicalRecord record) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('medical_records')
          .add({
        'title': record.title,
        'description': record.description,
        'details': record.details,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // REGISTROS MÉDICOS - Eliminar
  static Future<bool> deleteMedicalRecord(String recordId) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('medical_records')
          .doc(recordId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  // MÉDICOS FAVORITOS - Obtener
  static Future<List<Doctor>> getUserFavoriteDoctors() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('favorite_doctors')
          .get();

      return snapshot.docs
          .where((doc) => !doc.id.startsWith('_'))
          .map((doc) {
        final data = doc.data();
        return Doctor(
          id: doc.id,
          name: data['name'] ?? '',
          specialty: data['specialty'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          clinic: data['clinic'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // MÉDICOS FAVORITOS - Agregar
  static Future<bool> addFavoriteDoctor(Doctor doctor) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('favorite_doctors')
          .add({
        'name': doctor.name,
        'specialty': doctor.specialty,
        'phone': doctor.phone,
        'email': doctor.email,
        'clinic': doctor.clinic,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // MÉDICOS FAVORITOS - Eliminar
  static Future<bool> deleteFavoriteDoctor(String doctorId) async {
    try {
      if (_userId == null) return false;

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('favorite_doctors')
          .doc(doctorId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }
}

