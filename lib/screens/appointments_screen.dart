import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../services/user_data_service.dart';
import '../services/alert_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  String? _lastUserId;

  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final data = await UserDataService.getUserAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appointments = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _addAppointment() async {
    final doctor = _doctorController.text.trim();
    final specialty = _specialtyController.text.trim();
    final location = _locationController.text.trim();
    final reason = _reasonController.text.trim();

    if (doctor.isEmpty ||
        specialty.isEmpty ||
        location.isEmpty ||
        reason.isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campos incompletos',
        message: 'Completa todos los campos de la cita',
      );
      return;
    }

    final appointmentDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newAppointment = Appointment(
      doctorName: doctor,
      specialty: specialty,
      date: appointmentDate,
      reason: reason,
      location: location,
    );

    try {
      final success = await UserDataService.addAppointment(newAppointment);
      if (!mounted) return;
      if (success) {
        await _loadAppointments();
        if (!mounted) return;
        Navigator.of(context).pop();
        _clearForm();
        AlertService.operationComplete(
          context,
          operation: 'Cita creada correctamente',
        );
      } else {
        AlertService.operationFailed(
          context,
          operation: 'guardar la cita',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AlertService.operationFailed(
        context,
        operation: 'guardar la cita',
      );
    }
  }

  void _clearForm() {
    _doctorController.clear();
    _specialtyController.clear();
    _locationController.clear();
    _reasonController.clear();
    _selectedDate = DateTime.now().add(const Duration(days: 3));
    _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  }

  void _deleteAppointmentWithConfirm(String appointmentId, String doctorName) {
    AlertService.confirmDelete(
      context,
      itemName: 'cita con $doctorName',
      onConfirm: () async {
        try {
          final success = await UserDataService.deleteAppointment(appointmentId);
          if (!mounted) return;
          if (success) {
            await _loadAppointments();
            if (!mounted) return;
            AlertService.operationComplete(
              context,
              operation: 'Cita eliminada correctamente',
            );
          } else {
            AlertService.operationFailed(
              context,
              operation: 'eliminar la cita',
            );
          }
        } catch (_) {
          if (!mounted) return;
          AlertService.operationFailed(
            context,
            operation: 'eliminar la cita',
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showAddAppointmentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nueva cita',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Médico',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _specialtyController,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lugar',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Motivo de la consulta',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );

                              if (picked != null) {
                                setSheetState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined),
                                  const SizedBox(width: 10),
                                  Text(_formatDate(_selectedDate)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );

                              if (picked != null) {
                                setSheetState(() => _selectedTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addAppointment,
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar cita'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextAppointment = _appointments.isNotEmpty
        ? _appointments.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas médicas'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (nextAppointment != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2E7DFF),
                                    Color(0xFF4CAF50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Próxima consulta',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(nextAppointment.date),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${nextAppointment.specialty} • ${nextAppointment.doctorName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          const Text(
                            'Agenda',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    sliver: SliverList.separated(
                      itemCount: _appointments.isEmpty ? 1 : _appointments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (_appointments.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'No tienes citas registradas',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        final appointment = _appointments[index];

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.doctorName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${appointment.specialty} • ${appointment.location}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_formatDate(appointment.date)} • ${appointment.date.hour.toString().padLeft(2, '0')}:${appointment.date.minute.toString().padLeft(2, '0')}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        appointment.reason,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    final id = appointment.id;
                                    if (id == null) return;
                                    _deleteAppointmentWithConfirm(id, appointment.doctorName);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'appointments_fab',
        onPressed: _showAddAppointmentSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
    );
  }
}
