import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nuevo usuario')),
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
                        trailing: Chip(
                          label: Text(user['role']),
                          backgroundColor: _getRoleColor(user['role']),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ver detalles de ${user['name']}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
