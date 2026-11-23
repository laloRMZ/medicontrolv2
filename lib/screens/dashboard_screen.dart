import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/user.dart';
import '../models/user_medical_data.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/profile_pdf_service.dart';
import '../services/user_data_service.dart';
import '../widgets/medical_summary_card.dart';
import '../widgets/next_appointment_widget.dart';
import '../widgets/quick_actions_grid.dart';
import 'appointments_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'medical_records_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Appointment? _nextAppointment;
  bool _isLoadingAppointments = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final appointments = await UserDataService.getUserAppointments();
      final now = DateTime.now();
      final upcoming = appointments
          .where((a) => !a.date.isBefore(now))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _nextAppointment = upcoming.isNotEmpty
              ? upcoming.first
              : (appointments.isNotEmpty ? appointments.last : null);
          _isLoadingAppointments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  Future<void> _exportProfilePdf(AppUser user) async {
    try {
      final safeName = user.fullName.trim().isEmpty
          ? 'usuario'
          : user.fullName.trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.layoutPdf(
        name: 'perfil_medico_$safeName.pdf',
        onLayout: (_) => ProfilePdfService.buildMedicalProfilePdf(user),
      );
    } catch (e) {
      if (mounted) {
        AlertService.operationFailed(
          context,
          operation: 'generar el PDF del perfil médico',
          reason: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final medicalData = user?.medicalData ?? const UserMedicalData();

    return Scaffold(
      appBar: AppBar(
        title: const Text("MediControl"),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SALUDO
              Text(
                "Hola, ${user?.fullName ?? 'Usuario'} 👋",
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Tu información médica en un solo lugar",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ACCESOS RÁPIDOS
              const Text(
                'Accesos Rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              QuickActionsGrid(
                actions: [
                  QuickActionItem(
                    icon: Icons.edit_note,
                    label: 'Editar Perfil',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionItem(
                    icon: Icons.calendar_month,
                    label: 'Mis Citas',
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AppointmentsScreen(),
                        ),
                      );
                      _loadDashboardData();
                    },
                  ),
                  QuickActionItem(
                    icon: Icons.contact_emergency,
                    label: 'Emergencia',
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionItem(
                    icon: Icons.picture_as_pdf,
                    label: 'Perfil en PDF',
                    color: Colors.indigo,
                    onTap: () {
                      if (user != null) {
                        _exportProfilePdf(user);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // PRÓXIMA CITA
              if (_isLoadingAppointments)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                NextAppointmentWidget(
                  appointment: _nextAppointment,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                    _loadDashboardData();
                  },
                ),
              const SizedBox(height: 24),

              // RESUMEN MÉDICO REUTILIZABLE
              MedicalSummaryCard(
                medicalData: medicalData,
                onEditPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ACCESO A HISTORIAL MÉDICO
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.folder_shared, color: Colors.blue),
                  title: const Text('Registros Médicos'),
                  subtitle: const Text('Consulta y agrega tu historial'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MedicalRecordsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

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
                    _buildPersonalInfo(
                      '📱 Teléfono',
                      user?.phone.isEmpty ?? true ? '---' : user!.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
