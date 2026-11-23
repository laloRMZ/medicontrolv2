import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/user_medical_data.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isDoctor => _currentUser?.role == UserRole.doctor;

  Future<void> initialize() async {
    _isLoading = true;
    try {
      _currentUser = await FirebaseAuthService.getStoredUser();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FirebaseAuthService.login(email, password);
      _currentUser = result.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String phone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FirebaseAuthService.register(
        fullName,
        email,
        password,
        phone,
      );
      _currentUser = result.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await FirebaseAuthService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile(
    String fullName,
    String phone, {
    UserMedicalData? medicalData,
  }) async {
    try {
      await FirebaseAuthService.updateProfile(fullName, phone);
      if (medicalData != null) {
        await FirebaseAuthService.updateMedicalData(medicalData);
      }

      final updatedUser = await FirebaseAuthService.getStoredUser();
      if (updatedUser != null) {
        _currentUser = updatedUser;
      } else if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName,
          phone: phone,
          medicalData: medicalData,
        );
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileImage(String? profileImage) async {
    try {
      await FirebaseAuthService.updateProfileImage(profileImage);
      final updatedUser = await FirebaseAuthService.getStoredUser();
      if (updatedUser != null) {
        _currentUser = updatedUser;
      } else if (_currentUser != null) {
        _currentUser = AppUser(
          id: _currentUser!.id,
          fullName: _currentUser!.fullName,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          role: _currentUser!.role,
          profileImage: profileImage,
          createdAt: _currentUser!.createdAt,
          isActive: _currentUser!.isActive,
          specialty: _currentUser!.specialty,
          medicalData: _currentUser!.medicalData,
        );
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
