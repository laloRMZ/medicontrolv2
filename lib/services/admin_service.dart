import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../models/user.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalDoctors;
  final int appointmentsToday;
  final int openTickets;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalDoctors,
    required this.appointmentsToday,
    required this.openTickets,
  });
}

class UserActivitySummary {
  final int appointmentsCount;
  final int emergencyContactsCount;
  final int medicalRecordsCount;
  final int openSupportTickets;
  final bool hasMedicalData;

  const UserActivitySummary({
    required this.appointmentsCount,
    required this.emergencyContactsCount,
    required this.medicalRecordsCount,
    required this.openSupportTickets,
    required this.hasMedicalData,
  });
}

class AdminReportData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int patientsCount;
  final int doctorsCount;
  final int adminsCount;
  final int newUsersInPeriod;
  final int newDoctorsInPeriod;
  final int usersWithoutMedicalData;
  final int appointmentsInPeriod;
  final Map<String, int> appointmentsBySpecialty;
  final Map<String, int> appointmentsByDoctor;
  final int totalTicketsInPeriod;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final List<AppUser> recentUsers;

  const AdminReportData({
    required this.startDate,
    required this.endDate,
    required this.totalUsers,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.patientsCount,
    required this.doctorsCount,
    required this.adminsCount,
    required this.newUsersInPeriod,
    required this.newDoctorsInPeriod,
    required this.usersWithoutMedicalData,
    required this.appointmentsInPeriod,
    required this.appointmentsBySpecialty,
    required this.appointmentsByDoctor,
    required this.totalTicketsInPeriod,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.recentUsers,
  });
}

class AdminService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = fb.FirebaseAuth.instance;

  static String? get currentAdminId => _auth.currentUser?.uid;

  static Stream<List<AppUser>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map(_userFromDoc).toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  static AppUser _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppUser.fromJson({
      ...data,
      'id': doc.id,
      'createdAt':
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
    });
  }

  /// Crea un usuario en Firebase Auth usando una app secundaria temporal
  /// para no cerrar la sesión del administrador actual.
  static Future<AppUser> createUser({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? specialty,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final appName = 'admin_create_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user!.updateDisplayName(fullName.trim());
      final userId = credential.user!.uid;
      final now = Timestamp.now();
      final trimmedSpecialty =
          role == UserRole.doctor && specialty != null && specialty.trim().isNotEmpty
              ? specialty.trim()
              : null;

      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role.name.toUpperCase(),
        'isActive': true,
        'specialty': trimmedSpecialty,
        'profileImage': null,
        'createdAt': now,
        'updatedAt': now,
      });

      final subcollections = [
        'favorite_doctors',
        'appointments',
        'emergency_contacts',
        'medical_records',
      ];
      for (final sub in subcollections) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection(sub)
            .doc('_placeholder')
            .set({'_initialized': true});
      }

      await secondaryAuth.signOut();

      return AppUser(
        id: userId,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        isActive: true,
        specialty: trimmedSpecialty,
        createdAt: now.toDate(),
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('El correo ya está registrado.');
      } else if (e.code == 'weak-password') {
        throw Exception('La contraseña debe tener al menos 6 caracteres.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo no es válido.');
      }
      throw Exception(e.message ?? 'Error al crear la cuenta.');
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  static Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole.name.toUpperCase(),
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> updateUserDetails(
    String userId, {
    required String fullName,
    required String phone,
    String? specialty,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'specialty': specialty != null && specialty.trim().isNotEmpty
          ? specialty.trim()
          : null,
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  static Future<UserActivitySummary> getUserActivitySummary(
    String userId,
  ) async {
    int appointments = 0;
    int emergencyContacts = 0;
    int medicalRecords = 0;
    int openTickets = 0;
    bool hasMedicalData = false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      hasMedicalData = data != null && data['medicalData'] != null;

      final results = await Future.wait([
        _firestore
            .collection('users')
            .doc(userId)
            .collection('appointments')
            .get(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('emergency_contacts')
            .get(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('medical_records')
            .get(),
        _firestore.collection('support_chats').doc(userId).get(),
      ]);

      final apptSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final contactsSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final recordsSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final ticketDoc = results[3] as DocumentSnapshot<Map<String, dynamic>>;

      appointments =
          apptSnap.docs.where((d) => !d.id.startsWith('_')).length;
      emergencyContacts =
          contactsSnap.docs.where((d) => !d.id.startsWith('_')).length;
      medicalRecords =
          recordsSnap.docs.where((d) => !d.id.startsWith('_')).length;

      if (ticketDoc.exists) {
        final status = ticketDoc.data()?['status'] as String? ?? 'open';
        if (status == 'open' || status == 'inProgress') {
          openTickets = 1;
        }
      }
    } catch (_) {
      // Devolver resumen parcial si alguna subcolección no es accesible
    }

    return UserActivitySummary(
      appointmentsCount: appointments,
      emergencyContactsCount: emergencyContacts,
      medicalRecordsCount: medicalRecords,
      openSupportTickets: openTickets,
      hasMedicalData: hasMedicalData,
    );
  }

  static Future<AdminDashboardStats> getDashboardStats() async {
    int totalUsers = 0;
    int totalDoctors = 0;
    int appointmentsToday = 0;
    int openTickets = 0;

    try {
      final usersSnap = await _firestore.collection('users').get();
      totalUsers = usersSnap.docs.length;
      totalDoctors = usersSnap.docs.where((doc) {
        final role = (doc.data()['role'] as String? ?? '').toUpperCase();
        return role == 'DOCTOR';
      }).length;
    } catch (_) {}

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final apptsSnap = await _firestore.collectionGroup('appointments').get();
      appointmentsToday = apptsSnap.docs.where((doc) {
        if (doc.id.startsWith('_')) return false;
        final ts = doc.data()['date'] as Timestamp?;
        if (ts == null) return false;
        final date = ts.toDate();
        return !date.isBefore(startOfDay) && date.isBefore(endOfDay);
      }).length;
    } catch (_) {}

    try {
      final ticketsSnap = await _firestore.collection('support_chats').get();
      openTickets = ticketsSnap.docs.where((doc) {
        final status = doc.data()['status'] as String? ?? 'open';
        return status == 'open' || status == 'inProgress';
      }).length;
    } catch (_) {}

    return AdminDashboardStats(
      totalUsers: totalUsers,
      totalDoctors: totalDoctors,
      appointmentsToday: appointmentsToday,
      openTickets: openTickets,
    );
  }

  static Future<AdminReportData> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    int totalUsers = 0;
    int activeUsers = 0;
    int suspendedUsers = 0;
    int patientsCount = 0;
    int doctorsCount = 0;
    int adminsCount = 0;
    int newUsersInPeriod = 0;
    int newDoctorsInPeriod = 0;
    int usersWithoutMedicalData = 0;
    final List<AppUser> recentUsers = [];

    try {
      final usersSnap = await _firestore.collection('users').get();
      totalUsers = usersSnap.docs.length;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final user = _userFromDoc(doc);

        if (user.isActive) {
          activeUsers++;
        } else {
          suspendedUsers++;
        }

        switch (user.role) {
          case UserRole.admin:
            adminsCount++;
            break;
          case UserRole.doctor:
            doctorsCount++;
            break;
          case UserRole.user:
            patientsCount++;
            if (data['medicalData'] == null) {
              usersWithoutMedicalData++;
            }
            break;
        }

        if (!user.createdAt.isBefore(normalizedStart) &&
            !user.createdAt.isAfter(normalizedEnd)) {
          newUsersInPeriod++;
          if (user.role == UserRole.doctor) {
            newDoctorsInPeriod++;
          }
          recentUsers.add(user);
        }
      }

      recentUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}

    int appointmentsInPeriod = 0;
    final Map<String, int> appointmentsBySpecialty = {};
    final Map<String, int> appointmentsByDoctor = {};

    try {
      final apptsSnap = await _firestore.collectionGroup('appointments').get();
      for (final doc in apptsSnap.docs) {
        if (doc.id.startsWith('_')) continue;
        final data = doc.data();
        final ts = data['date'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate();

        if (!date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd)) {
          appointmentsInPeriod++;
          final specialty =
              (data['specialty'] as String? ?? '').trim().isNotEmpty
                  ? (data['specialty'] as String).trim()
                  : 'General';
          final doctorName =
              (data['doctorName'] as String? ?? '').trim().isNotEmpty
                  ? (data['doctorName'] as String).trim()
                  : 'Sin asignar';

          appointmentsBySpecialty[specialty] =
              (appointmentsBySpecialty[specialty] ?? 0) + 1;
          appointmentsByDoctor[doctorName] =
              (appointmentsByDoctor[doctorName] ?? 0) + 1;
        }
      }
    } catch (_) {}

    int totalTicketsInPeriod = 0;
    int openTickets = 0;
    int inProgressTickets = 0;
    int resolvedTickets = 0;

    try {
      final ticketsSnap = await _firestore.collection('support_chats').get();
      for (final doc in ticketsSnap.docs) {
        final data = doc.data();
        final updatedTs =
            (data['updatedAt'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
        final updatedAt = updatedTs?.toDate();
        if (updatedAt != null &&
            (updatedAt.isBefore(normalizedStart) ||
                updatedAt.isAfter(normalizedEnd))) {
          continue;
        }
        totalTicketsInPeriod++;
        final status = data['status'] as String? ?? 'open';
        if (status == 'resolved') {
          resolvedTickets++;
        } else if (status == 'inProgress') {
          inProgressTickets++;
        } else {
          openTickets++;
        }
      }
    } catch (_) {}

    return AdminReportData(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      suspendedUsers: suspendedUsers,
      patientsCount: patientsCount,
      doctorsCount: doctorsCount,
      adminsCount: adminsCount,
      newUsersInPeriod: newUsersInPeriod,
      newDoctorsInPeriod: newDoctorsInPeriod,
      usersWithoutMedicalData: usersWithoutMedicalData,
      appointmentsInPeriod: appointmentsInPeriod,
      appointmentsBySpecialty: appointmentsBySpecialty,
      appointmentsByDoctor: appointmentsByDoctor,
      totalTicketsInPeriod: totalTicketsInPeriod,
      openTickets: openTickets,
      inProgressTickets: inProgressTickets,
      resolvedTickets: resolvedTickets,
      recentUsers: recentUsers,
    );
  }

  static String buildReportCsv(AdminReportData data) {
    final buffer = StringBuffer();
    String esc(Object value) {
      final s = value.toString().replaceAll('"', '""');
      return '"$s"';
    }

    buffer.writeln('Seccion,Indicador,Valor');
    buffer.writeln(
      'Periodo,Inicio,${esc(data.startDate.toIso8601String().split('T').first)}',
    );
    buffer.writeln(
      'Periodo,Fin,${esc(data.endDate.toIso8601String().split('T').first)}',
    );
    buffer.writeln('Usuarios,Total,${data.totalUsers}');
    buffer.writeln('Usuarios,Activos,${data.activeUsers}');
    buffer.writeln('Usuarios,Suspendidos,${data.suspendedUsers}');
    buffer.writeln('Usuarios,Pacientes,${data.patientsCount}');
    buffer.writeln('Usuarios,Medicos,${data.doctorsCount}');
    buffer.writeln('Usuarios,Administradores,${data.adminsCount}');
    buffer.writeln('Usuarios,Nuevos en periodo,${data.newUsersInPeriod}');
    buffer.writeln('Usuarios,Sin datos medicos,${data.usersWithoutMedicalData}');
    buffer.writeln('Citas,Total en periodo,${data.appointmentsInPeriod}');
    for (final entry in data.appointmentsBySpecialty.entries) {
      buffer.writeln('Citas por especialidad,${esc(entry.key)},${entry.value}');
    }
    for (final entry in data.appointmentsByDoctor.entries) {
      buffer.writeln('Citas por medico,${esc(entry.key)},${entry.value}');
    }
    buffer.writeln('Soporte,Total tickets,${data.totalTicketsInPeriod}');
    buffer.writeln('Soporte,Abiertos,${data.openTickets}');
    buffer.writeln('Soporte,En progreso,${data.inProgressTickets}');
    buffer.writeln('Soporte,Resueltos,${data.resolvedTickets}');

    return buffer.toString();
  }
}
