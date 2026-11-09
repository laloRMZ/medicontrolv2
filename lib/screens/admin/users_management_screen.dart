import 'package:flutter/material.dart';
import '../../services/alert_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _users = [
          {
            'id': 1,
            'name': 'Juan García',
            'email': 'juan@example.com',
            'role': 'USER',
            'createdAt': '2024-01-15',
          },
          {
            'id': 2,
            'name': 'Dr. María López',
            'email': 'maria@example.com',
            'role': 'DOCTOR',
            'createdAt': '2024-01-10',
          },
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'DOCTOR':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _deleteUserWithConfirm(String userId, String userName) {
    AlertService.confirmDelete(
      context,
      itemName: 'usuario $userName',
      onConfirm: () {
        // Simular eliminación
        setState(() {
          _users.removeWhere((user) => user['id'].toString() == userId);
        });
        AlertService.operationComplete(
          context,
          operation: 'Usuario eliminado correctamente',
        );
      },
    );
  }

  void _changeUserRoleWithConfirm(
    String userId,
    String userName,
    String currentRole,
  ) {
    final newRole = currentRole == 'DOCTOR' ? 'ADMIN' : 'DOCTOR';
    AlertService.confirmStatusChange(
      context,
      currentStatus: currentRole,
      newStatus: newRole,
      onConfirm: () {
        // Simular cambio de rol
        final userIndex = _users.indexWhere((u) => u['id'].toString() == userId);
        if (userIndex != -1) {
          setState(() {
            _users[userIndex]['role'] = newRole;
          });
        }
        AlertService.operationComplete(
          context,
          operation: 'Rol de $userName actualizado a $newRole',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AlertService.showInfo(
            context,
            title: 'Crear usuario',
            message: 'Función de crear usuarios en desarrollo',
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No hay usuarios registrados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user['name'][0]),
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.security, size: 18),
                                  SizedBox(width: 8),
                                  Text('Cambiar rol'),
                                ],
                              ),
                              onTap: () {
                                _changeUserRoleWithConfirm(
                                  user['id'].toString(),
                                  user['name'],
                                  user['role'],
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar usuario', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () {
                                _deleteUserWithConfirm(
                                  user['id'].toString(),
                                  user['name'],
                                );
                              },
                            ),
                          ],
                          child: Chip(
                            label: Text(user['role']),
                            backgroundColor: _getRoleColor(user['role']),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
