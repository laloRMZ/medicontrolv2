import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/alert_service.dart';

enum _UserStatusFilter { all, active, suspended }

class UsersManagementScreen extends StatefulWidget {
  final UserRole? initialRoleFilter;

  const UsersManagementScreen({super.key, this.initialRoleFilter});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _roleFilter;
  _UserStatusFilter _statusFilter = _UserStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _roleFilter = widget.initialRoleFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.doctor:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.doctor:
        return 'MÉDICO';
      case UserRole.user:
        return 'PACIENTE';
    }
  }

  List<AppUser> _applyFilters(List<AppUser> users) {
    return users.where((user) {
      if (_roleFilter != null && user.role != _roleFilter) {
        return false;
      }
      if (_statusFilter == _UserStatusFilter.active && !user.isActive) {
        return false;
      }
      if (_statusFilter == _UserStatusFilter.suspended && user.isActive) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = user.fullName.toLowerCase().contains(q);
        final matchesEmail = user.email.toLowerCase().contains(q);
        final matchesSpecialty =
            (user.specialty ?? '').toLowerCase().contains(q);
        if (!matchesName && !matchesEmail && !matchesSpecialty) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _isSelf(AppUser user) => user.id == AdminService.currentAdminId;

  Future<void> _showCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();
    UserRole selectedRole = UserRole.user;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Crear Usuario / Médico'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña inicial',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.security_outlined),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(_getRoleLabel(role)),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  setModalState(() => selectedRole = val);
                                }
                              },
                      ),
                      if (selectedRole == UserRole.doctor) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: specialtyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Especialidad médica',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa la especialidad'
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);
                          try {
                            await AdminService.createUser(
                              fullName: nameCtrl.text,
                              email: emailCtrl.text,
                              password: passwordCtrl.text,
                              phone: phoneCtrl.text,
                              role: selectedRole,
                              specialty: specialtyCtrl.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (mounted) {
                              AlertService.showSuccessToast(
                                this.context,
                                'Usuario creado correctamente',
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              AlertService.showErrorToast(
                                this.context,
                                e.toString().replaceFirst('Exception: ', ''),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    specialtyCtrl.dispose();
  }

  Future<void> _showChangeRoleDialog(AppUser user) async {
    UserRole selectedRole = user.role;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Cambiar rol de ${user.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: UserRole.values.map((role) {
                  final disabledSelfDemote =
                      _isSelf(user) && role != UserRole.admin;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedRole == role
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: disabledSelfDemote
                          ? Colors.grey
                          : _getRoleColor(role),
                    ),
                    title: Text(_getRoleLabel(role)),
                    subtitle: disabledSelfDemote
                        ? const Text(
                            'No puedes quitar tu propio rol de admin',
                            style: TextStyle(fontSize: 12),
                          )
                        : null,
                    enabled: !disabledSelfDemote,
                    onTap: disabledSelfDemote
                        ? null
                        : () => setModalState(() => selectedRole = role),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedRole == user.role
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          try {
                            await AdminService.updateUserRole(
                              user.id,
                              selectedRole,
                            );
                            if (mounted) {
                              AlertService.showSuccessToast(
                                this.context,
                                'Rol actualizado a ${_getRoleLabel(selectedRole)}',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              AlertService.showErrorToast(
                                this.context,
                                'Error actualizando rol: $e',
                              );
                            }
                          }
                        },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleUserStatus(AppUser user) {
    if (_isSelf(user)) {
      AlertService.showWarningToast(
        context,
        'No puedes suspender tu propia cuenta de administrador',
      );
      return;
    }

    final targetStatus = !user.isActive;
    AlertService.confirmStatusChange(
      context,
      currentStatus: user.isActive ? 'Activo' : 'Suspendido',
      newStatus: targetStatus ? 'Activo' : 'Suspendido',
      onConfirm: () async {
        try {
          await AdminService.toggleUserStatus(user.id, targetStatus);
          if (mounted) {
            AlertService.showSuccessToast(
              context,
              targetStatus
                  ? 'Usuario reactivado correctamente'
                  : 'Usuario suspendido correctamente',
            );
          }
        } catch (e) {
          if (mounted) {
            AlertService.showErrorToast(context, 'Error cambiando estado: $e');
          }
        }
      },
    );
  }

  void _deleteUserWithConfirm(AppUser user) {
    if (_isSelf(user)) {
      AlertService.showWarningToast(
        context,
        'No puedes eliminar tu propia cuenta',
      );
      return;
    }

    AlertService.confirmDelete(
      context,
      itemName: 'usuario ${user.fullName}',
      onConfirm: () async {
        try {
          await AdminService.deleteUser(user.id);
          if (mounted) {
            AlertService.showSuccessToast(
              context,
              'Usuario eliminado de la plataforma',
            );
          }
        } catch (e) {
          if (mounted) {
            AlertService.showErrorToast(context, 'Error eliminando: $e');
          }
        }
      },
    );
  }

  void _showUserDetailSheet(AppUser user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final specialtyCtrl = TextEditingController(text: user.specialty ?? '');
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              _getRoleColor(user.role).withValues(alpha: 0.15),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(user.role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(_getRoleLabel(user.role)),
                          backgroundColor: _getRoleColor(user.role),
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Registrado el ${DateFormat('dd/MM/yyyy').format(user.createdAt)} • Estado: ${user.isActive ? 'Activo' : 'Suspendido'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<UserActivitySummary>(
                      future: AdminService.getUserActivitySummary(user.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: LinearProgressIndicator()),
                          );
                        }
                        final summary = snapshot.data;
                        if (summary == null) return const SizedBox.shrink();
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSummaryChip(
                              Icons.calendar_today,
                              '${summary.appointmentsCount} citas',
                              Colors.blue,
                            ),
                            _buildSummaryChip(
                              Icons.contact_phone,
                              '${summary.emergencyContactsCount} contactos',
                              Colors.teal,
                            ),
                            _buildSummaryChip(
                              Icons.folder_shared,
                              '${summary.medicalRecordsCount} expedientes',
                              Colors.purple,
                            ),
                            _buildSummaryChip(
                              Icons.medical_information,
                              summary.hasMedicalData
                                  ? 'Ficha médica OK'
                                  : 'Sin ficha médica',
                              summary.hasMedicalData
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Editar información básica',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (user.role == UserRole.doctor) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: specialtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar cambios'),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                try {
                                  await AdminService.updateUserDetails(
                                    user.id,
                                    fullName: nameCtrl.text,
                                    phone: phoneCtrl.text,
                                    specialty: specialtyCtrl.text,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  if (mounted) {
                                    AlertService.showSuccessToast(
                                      this.context,
                                      'Datos actualizados correctamente',
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (mounted) {
                                    AlertService.showErrorToast(
                                      this.context,
                                      'Error al actualizar: $e',
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      specialtyCtrl.dispose();
    });
  }

  Widget _buildSummaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o especialidad...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pacientes'),
                  selected: _roleFilter == UserRole.user,
                  onSelected: (_) =>
                      setState(() => _roleFilter = UserRole.user),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Médicos'),
                  selected: _roleFilter == UserRole.doctor,
                  onSelected: (_) =>
                      setState(() => _roleFilter = UserRole.doctor),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Admins'),
                  selected: _roleFilter == UserRole.admin,
                  onSelected: (_) =>
                      setState(() => _roleFilter = UserRole.admin),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Activos'),
                  selected: _statusFilter == _UserStatusFilter.active,
                  onSelected: (selected) => setState(() {
                    _statusFilter = selected
                        ? _UserStatusFilter.active
                        : _UserStatusFilter.all;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Suspendidos'),
                  selected: _statusFilter == _UserStatusFilter.suspended,
                  onSelected: (selected) => setState(() {
                    _statusFilter = selected
                        ? _UserStatusFilter.suspended
                        : _UserStatusFilter.all;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: AdminService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudieron cargar los usuarios.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final filteredUsers = _applyFilters(allUsers);

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No hay usuarios que coincidan con el filtro'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final roleColor = _getRoleColor(user.role);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _showUserDetailSheet(user),
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                    : 'Sin nombre',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!user.isActive)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Suspendido',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            if (user.specialty != null &&
                                user.specialty!.isNotEmpty)
                              Text(
                                user.specialty!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                _getRoleLabel(user.role),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: roleColor,
                              visualDensity: VisualDensity.compact,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'detail':
                                    _showUserDetailSheet(user);
                                    break;
                                  case 'role':
                                    _showChangeRoleDialog(user);
                                    break;
                                  case 'status':
                                    _toggleUserStatus(user);
                                    break;
                                  case 'delete':
                                    _deleteUserWithConfirm(user);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('Ver detalle'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'role',
                                  child: Row(
                                    children: [
                                      Icon(Icons.security, size: 18),
                                      SizedBox(width: 8),
                                      Text('Cambiar rol'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'status',
                                  child: Row(
                                    children: [
                                      Icon(
                                        user.isActive
                                            ? Icons.block
                                            : Icons.check_circle_outline,
                                        size: 18,
                                        color: user.isActive
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.isActive
                                            ? 'Suspender'
                                            : 'Reactivar',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Eliminar usuario',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
