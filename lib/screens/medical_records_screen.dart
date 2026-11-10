import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medical_record.dart';
import '../providers/auth_provider.dart';
import '../services/user_data_service.dart';
import '../services/alert_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  List<MedicalRecord> _records = [];
  String? _lastUserId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    try {
      final data = await UserDataService.getUserMedicalRecords();
      if (!mounted) return;
      setState(() {
        _records = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _detailController.clear();
  }

  void _deleteRecordWithConfirm(String recordId, String recordTitle) {
    AlertService.confirmDelete(
      context,
      itemName: 'registro médico ($recordTitle)',
      onConfirm: () async {
        try {
          final success = await UserDataService.deleteMedicalRecord(recordId);
          if (!mounted) return;
          if (success) {
            await _loadRecords();
            if (!mounted) return;
            AlertService.operationComplete(
              context,
              operation: 'Registro eliminado correctamente',
            );
          } else {
            AlertService.operationFailed(
              context,
              operation: 'eliminar el registro',
            );
          }
        } catch (_) {
          if (!mounted) return;
          AlertService.operationFailed(
            context,
            operation: 'eliminar el registro',
          );
        }
      },
    );
  }

  Future<void> _addRecord() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final detail = _detailController.text.trim();

    if (title.isEmpty || description.isEmpty || detail.isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campos incompletos',
        message: 'Completa todos los campos del registro',
      );
      return;
    }

    final record = MedicalRecord(
      title: title,
      description: description,
      details: [detail],
    );

    try {
      final success = await UserDataService.addMedicalRecord(record);
      if (!mounted) return;
      if (success) {
        await _loadRecords();
        if (!mounted) return;
        Navigator.of(context).pop();
        _clearForm();
        AlertService.operationComplete(
          context,
          operation: 'Registro médico creado correctamente',
        );
      } else {
        AlertService.operationFailed(
          context,
          operation: 'guardar el registro',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AlertService.operationFailed(
        context,
        operation: 'guardar el registro',
      );
    }
  }

  void _showAddRecordSheet() {
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
                  'Nuevo registro',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título del registro',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailController,
                  decoration: const InputDecoration(
                    labelText: 'Detalle importante',
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addRecord,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar registro'),
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
      appBar: AppBar(title: const Text('Información médica')),
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
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.medical_information, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Resumen clínico y antecedente personal',
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
                      'Registros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _records.isEmpty ? 1 : _records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (_records.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No tienes registros médicos',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }
                          final record = _records[index];
                          return Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              title: Text(
                                record.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(record.description),
                              children: [
                                ...record.details.map(
                                  (detail) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(detail)),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () {
                                      final id = record.id;
                                      if (id == null) return;
                                      _deleteRecordWithConfirm(id, record.title);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
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
        heroTag: 'medical_records_fab',
        onPressed: _showAddRecordSheet,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
