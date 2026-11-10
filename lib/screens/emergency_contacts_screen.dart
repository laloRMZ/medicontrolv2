import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../providers/auth_provider.dart';
import '../services/user_data_service.dart';
import '../services/alert_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  String? _lastUserId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    try {
      final data = await UserDataService.getUserEmergencyContacts();
      if (!mounted) return;
      setState(() {
        _contacts = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contacts = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _relationController.clear();
    _phoneController.clear();
    _notesController.clear();
  }

  void _deleteContactWithConfirm(String contactId, String contactName) {
    AlertService.confirmDelete(
      context,
      itemName: 'contacto $contactName',
      onConfirm: () async {
        try {
          final success = await UserDataService.deleteEmergencyContact(contactId);
          if (!mounted) return;
          if (success) {
            await _loadContacts();
            if (!mounted) return;
            AlertService.operationComplete(
              context,
              operation: 'Contacto eliminado correctamente',
            );
          } else {
            AlertService.operationFailed(
              context,
              operation: 'eliminar el contacto',
            );
          }
        } catch (_) {
          if (!mounted) return;
          AlertService.operationFailed(
            context,
            operation: 'eliminar el contacto',
          );
        }
      },
    );
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final relation = _relationController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    if ([name, relation, phone, notes].any((value) => value.isEmpty)) {
      AlertService.showWarning(
        context,
        title: 'Campos incompletos',
        message: 'Completa todos los datos del contacto',
      );
      return;
    }

    final contact = EmergencyContact(
      name: name,
      relation: relation,
      phone: phone,
      notes: notes,
    );

    try {
      final success = await UserDataService.addEmergencyContact(contact);
      if (!mounted) return;
      if (success) {
        await _loadContacts();
        if (!mounted) return;
        Navigator.of(context).pop();
        _clearForm();
        AlertService.operationComplete(
          context,
          operation: 'Contacto agregado correctamente',
        );
      } else {
        AlertService.operationFailed(
          context,
          operation: 'guardar el contacto',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AlertService.operationFailed(
        context,
        operation: 'guardar el contacto',
      );
    }
  }

  void _showAddContactSheet() {
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
                  'Nuevo contacto',
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
                  controller: _relationController,
                  decoration: const InputDecoration(
                    labelText: 'Relación',
                    prefixIcon: Icon(Icons.people_outline),
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
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Información adicional',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar contacto'),
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
      appBar: AppBar(title: const Text('Contactos de emergencia')),
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Personas de confianza para situaciones de emergencia',
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
                      'Contactos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 90),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(3),
                                3: FixedColumnWidth(48),
                              },
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              children: [
                                const TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Nombre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Relación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Teléfono',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox.shrink(),
                                  ],
                                ),
                                if (_contacts.isEmpty)
                                  const TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text(
                                            'No tienes contactos de emergencia',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox.shrink(),
                                      SizedBox.shrink(),
                                      SizedBox.shrink(),
                                    ],
                                  )
                                else
                                  for (final contact in _contacts)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                contact.notes,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(contact.relation),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(contact.phone),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            final id = contact.id;
                                            if (id == null) return;
                                            _deleteContactWithConfirm(id, contact.name);
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'emergency_contacts_fab',
        onPressed: _showAddContactSheet,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
