import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../services/user_data_service.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<Doctor> _doctors = [];
  String? _lastUserId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadDoctors();
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final data = await UserDataService.getUserFavoriteDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctors = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _specialtyController.clear();
    _phoneController.clear();
    _emailController.clear();
    _clinicController.clear();
  }

  Future<void> _addDoctor() async {
    final name = _nameController.text.trim();
    final specialty = _specialtyController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final clinic = _clinicController.text.trim();

    if ([name, specialty, phone, email, clinic].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los datos del profesional'),
        ),
      );
      return;
    }

    final doctor = Doctor(
      name: name,
      specialty: specialty,
      phone: phone,
      email: email,
      clinic: clinic,
    );

    try {
      final success = await UserDataService.addFavoriteDoctor(doctor);
      if (!mounted) return;
      if (success) {
        await _loadDoctors();
        Navigator.of(context).pop();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el médico'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el médico'),
        ),
      );
    }
  }

  void _showAddDoctorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
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
                  'Nuevo profesional',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clinicController,
                  decoration: const InputDecoration(
                    labelText: 'Clínica o consultorio',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addDoctor,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar profesional'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Médicos')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_hospital, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tu equipo médico y especialistas',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Profesionales',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth >= 600
                              ? (constraints.maxWidth - 14) / 2
                              : constraints.maxWidth;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 90),
                            child: _doctors.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        'No tienes médicos favoritos',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: [
                                      for (final doctor in _doctors)
                                        SizedBox(
                                          width: cardWidth,
                                          child: Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        leading: CircleAvatar(
                                          radius: 28,
                                          backgroundColor:
                                              Colors.green.shade100,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        title: Text(
                                          doctor.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(doctor.specialty),
                                              const SizedBox(height: 4),
                                              Text(doctor.clinic),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.phone_outlined,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(doctor.phone),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.email_outlined,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(doctor.email),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          onPressed: () async {
                                            final id = doctor.id;
                                            if (id == null) return;
                                            try {
                                              final success = await UserDataService.deleteFavoriteDoctor(id);
                                              if (!mounted) return;
                                              if (success) {
                                                await _loadDoctors();
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'No se pudo eliminar el médico',
                                                        ),
                                                      ),
                                                    );
                                              }
                                            } catch (_) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'No se pudo eliminar el médico',
                                                      ),
                                                    ),
                                                  );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'doctors_fab',
        onPressed: _showAddDoctorSheet,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
