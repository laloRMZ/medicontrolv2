import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'appointments_screen.dart';
import 'dashboard_screen.dart';
import 'doctors_screen.dart';
import 'emergency_contacts_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  List<Widget> _getScreens(UserRole role) {
    if (role == UserRole.admin) {
      return [
        const AdminDashboardScreen(),
        const DoctorsScreen(),
        const AppointmentsScreen(),
        const ProfileScreen(),
      ];
    }
    return [
      const DashboardScreen(),
      const AppointmentsScreen(),
      const DoctorsScreen(),
      const EmergencyContactsScreen(),
      const ProfileScreen(),
    ];
  }

  List<NavigationDestination> _getNavDestinations(UserRole role) {
    final userDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Citas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.medical_services_outlined),
        selectedIcon: Icon(Icons.medical_services),
        label: 'Médicos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.warning_amber_outlined),
        selectedIcon: Icon(Icons.warning_amber),
        label: 'Emergencia',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    final adminDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.medical_services_outlined),
        selectedIcon: Icon(Icons.medical_services),
        label: 'Médicos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Citas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    return role == UserRole.admin ? adminDestinations : userDestinations;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const LoginScreen();
        }

        final screens = _getScreens(user.role);
        final navDestinations = _getNavDestinations(user.role);

        return Scaffold(
          appBar: AppBar(
            title: const Text('MediControl'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Tooltip(
                    message: '${user.fullName} (${user.role.name})',
                    child: Text(
                      user.fullName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Cerrar sesión'),
                    onTap: () {
                      authProvider.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: navDestinations,
          ),
        );
      },
    );
  }
}
