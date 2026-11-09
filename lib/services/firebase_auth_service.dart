import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/user_medical_data.dart';

class FirebaseAuthService {
  static final _auth = fb.FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  static AppUser? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return AppUser(
      id: user.uid,
      fullName: user.displayName ?? 'Usuario',
      email: user.email ?? '',
      phone: '',
      role: UserRole.user,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  // Login con email y contraseña
  static Future<({AppUser user, String token})> login(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en base de datos');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final user = AppUser.fromJson({
        'id': credential.user!.uid,
        'fullName': userData['fullName'] ?? credential.user!.displayName ?? '',
        'email': userData['email'] ?? email,
        'phone': userData['phone'] ?? '',
        'role': userData['role'] ?? 'USER',
        'profileImage': userData['profileImage'],
        'createdAt':
            (userData['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
            DateTime.now().toIso8601String(),
      });

      final token = await credential.user!.getIdToken();

      return (user: user, token: token ?? '');
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('El usuario no existe');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido');
      }
      throw Exception('Error en login: ${e.message}');
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // Registro con email y contraseña
  static Future<({AppUser user, String token})> register(
    String fullName,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(fullName);

      final userId = credential.user!.uid;

      // Crear documento del usuario
      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': 'USER',
        'profileImage': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Crear subcollections vacías
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_doctors')
          .doc('_placeholder')
          .set({'_initialized': true});

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .doc('_placeholder')
          .set({'_initialized': true});

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc('_placeholder')
          .set({'_initialized': true});

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_records')
          .doc('_placeholder')
          .set({'_initialized': true});

      final user = AppUser(
        id: userId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: UserRole.user,
        createdAt: DateTime.now(),
      );

      final token = await credential.user!.getIdToken();

      return (user: user, token: token ?? '');
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('La contraseña es muy débil');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('El email ya está registrado');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido');
      }
      throw Exception('Error en registro: ${e.message}');
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Obtener usuario actual desde Firestore
  static Future<AppUser?> getStoredUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return AppUser.fromJson({
        'id': user.uid.hashCode,
        'fullName': userData['fullName'] ?? user.displayName ?? '',
        'email': userData['email'] ?? user.email ?? '',
        'phone': userData['phone'] ?? '',
        'role': userData['role'] ?? 'USER',
        'profileImage': userData['profileImage'],
        'createdAt':
            (userData['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return null;
    }
  }

  // Verificar si está autenticado
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Obtener UID del usuario actual
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Obtener token actual
  static Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Resetear contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error enviando email de reseteo: $e');
    }
  }

  // Actualizar perfil
  static Future<void> updateProfile(String fullName, String phone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await user.updateDisplayName(fullName);

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'phone': phone,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  // Obtener usuarios (para admin)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser.fromJson({
          ...data,
          'id': doc.id,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  // Cambiar rol de usuario (admin only)
  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No autenticado');

      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error actualizando rol: $e');
    }
  }

  // Eliminar usuario (admin only)
  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error eliminando usuario: $e');
    }
  }

  // Guardar datos médicos
  static Future<void> updateMedicalData(UserMedicalData medicalData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _firestore.collection('users').doc(user.uid).update({
        'medicalData': medicalData.toJson(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error guardando datos médicos: $e');
    }
  }

  // Obtener datos médicos
  static Future<UserMedicalData?> getMedicalData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      final medicalDataJson = data['medicalData'] as Map<String, dynamic>?;

      if (medicalDataJson == null) return null;
      return UserMedicalData.fromJson(medicalDataJson);
    } catch (e) {
      return null;
    }
  }
}
