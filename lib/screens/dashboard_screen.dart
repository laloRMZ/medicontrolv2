import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_auth_service.dart';
import '../models/user_medical_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  UserMedicalData? _medicalData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMedicalData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMedicalData();
    }
  }

  Future<void> _loadMedicalData() async {
    try {
      final data = await FirebaseAuthService.getMedicalData();
      if (mounted) {
        setState(() {
          _medicalData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasMedicalData = _medicalData != null && !_medicalData!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MediControl"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SALUDO
            Text(
              "Hola, ${user?.fullName ?? 'Usuario'} 👋",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Tu información médica en un solo lugar",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),

            // SI NO TIENE DATOS MÉDICOS
            if (!hasMedicalData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Completa tu perfil médico',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Agrega tu información médica para un mejor seguimiento de tu salud.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              // DATOS MÉDICOS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu Información Médica',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // Tipo de Sangre
                  if (_medicalData!.bloodType.isNotEmpty)
                    _buildInfoCard(
                      '🩸 Tipo de Sangre',
                      _medicalData!.bloodType,
                      Colors.red,
                    ),
                  if (_medicalData!.bloodType.isNotEmpty)
                    const SizedBox(height: 12),
                  // Alergias
                  if (_medicalData!.allergies.isNotEmpty)
                    _buildInfoCard(
                      '⚠️ Alergias',
                      _medicalData!.allergies,
                      Colors.orange,
                    ),
                  if (_medicalData!.allergies.isNotEmpty)
                    const SizedBox(height: 12),
                  // Contacto de Emergencia
                  if (_medicalData!.emergencyContactName.isNotEmpty)
                    _buildInfoCard(
                      '📞 Contacto de Emergencia',
                      '${_medicalData!.emergencyContactName}\n${_medicalData!.emergencyContactPhone}',
                      Colors.red,
                    ),
                  if (_medicalData!.emergencyContactName.isNotEmpty)
                    const SizedBox(height: 12),
                  // Notas
                  if (_medicalData!.notes.isNotEmpty)
                    _buildInfoCard(
                      '📋 Notas Médicas',
                      _medicalData!.notes,
                      Colors.blue,
                    ),
                ],
              ),

            const SizedBox(height: 30),

            // DATOS PERSONALES
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPersonalInfo('👤 Nombre', user?.fullName ?? '---'),
                  const SizedBox(height: 8),
                  _buildPersonalInfo('📧 Email', user?.email ?? '---'),
                  const SizedBox(height: 8),
                  _buildPersonalInfo('📱 Teléfono', user?.phone.isEmpty ?? true ? '---' : user!.phone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
