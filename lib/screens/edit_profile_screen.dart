import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_medical_data.dart';
import '../services/firebase_auth_service.dart';
import '../services/alert_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _notesController;

  bool _isLoading = false;
  bool _isLoadingMedicalData = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMedicalDataIfNeeded();
  }

  void _initializeControllers() {
    final user = context.read<AuthProvider>().currentUser;
    final medicalData = user?.medicalData;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bloodTypeController =
        TextEditingController(text: medicalData?.bloodType ?? '');
    _allergiesController =
        TextEditingController(text: medicalData?.allergies ?? '');
    _emergencyContactNameController =
        TextEditingController(text: medicalData?.emergencyContactName ?? '');
    _emergencyContactPhoneController =
        TextEditingController(text: medicalData?.emergencyContactPhone ?? '');
    _notesController = TextEditingController(text: medicalData?.notes ?? '');
  }

  Future<void> _loadMedicalDataIfNeeded() async {
    final currentMedical = context.read<AuthProvider>().currentUser?.medicalData;
    if (currentMedical != null && !currentMedical.isEmpty) return;

    setState(() => _isLoadingMedicalData = true);
    try {
      final fetched = await FirebaseAuthService.getMedicalData();
      if (!mounted || fetched == null || fetched.isEmpty) return;

      if (_bloodTypeController.text.isEmpty) {
        _bloodTypeController.text = fetched.bloodType;
      }
      if (_allergiesController.text.isEmpty) {
        _allergiesController.text = fetched.allergies;
      }
      if (_emergencyContactNameController.text.isEmpty) {
        _emergencyContactNameController.text = fetched.emergencyContactName;
      }
      if (_emergencyContactPhoneController.text.isEmpty) {
        _emergencyContactPhoneController.text = fetched.emergencyContactPhone;
      }
      if (_notesController.text.isEmpty) {
        _notesController.text = fetched.notes;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMedicalData = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campo requerido',
        message: 'El nombre es requerido',
      );
      return;
    }

    AlertService.confirmSave(
      context,
      onConfirm: () async {
        setState(() => _isLoading = true);

        try {
          final authProvider = context.read<AuthProvider>();

          final medicalData = UserMedicalData(
            bloodType: _bloodTypeController.text.trim(),
            allergies: _allergiesController.text.trim(),
            emergencyContactName: _emergencyContactNameController.text.trim(),
            emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
            notes: _notesController.text.trim(),
          );

          final ok = await authProvider.updateProfile(
            _fullNameController.text.trim(),
            _phoneController.text.trim(),
            medicalData: medicalData,
          );

          if (!mounted) return;
          if (ok) {
            AlertService.operationComplete(
              context,
              operation: 'Perfil actualizado',
              onDismiss: () {
                Navigator.of(context).pop(true);
              },
            );
          } else {
            AlertService.operationFailed(
              context,
              operation: 'actualizar el perfil',
              reason: authProvider.errorMessage ?? 'Error desconocido',
            );
          }
        } catch (e) {
          if (mounted) {
            AlertService.operationFailed(
              context,
              operation: 'actualizar el perfil',
              reason: e.toString(),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATOS PERSONALES
            const Text(
              'Datos Personales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // DATOS MÉDICOS
            const Text(
              'Datos Médicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bloodTypeController,
              decoration: InputDecoration(
                labelText: 'Tipo de Sangre (ej: O+)',
                prefixIcon: const Icon(Icons.bloodtype),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: 'Alergias (separadas por comas)',
                prefixIcon: const Icon(Icons.warning),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas Médicas',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            // CONTACTO DE EMERGENCIA
            const Text(
              'Contacto de Emergencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyContactNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Contacto',
                prefixIcon: const Icon(Icons.contact_emergency),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyContactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono de Emergencia',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || _isLoadingMedicalData)
                    ? null
                    : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
