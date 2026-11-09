import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  bool obscurePassword = true;
  bool isLogin = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthProvider authProvider) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campos incompletos',
        message: 'Por favor completa el email y la contraseña',
      );
      return;
    }

    bool success;
    if (isLogin) {
      success = await authProvider.login(email, password);
    } else {
      final fullName = fullNameController.text.trim();
      final phone = phoneController.text.trim();
      if (fullName.isEmpty || phone.isEmpty) {
        AlertService.showWarning(
          context,
          title: 'Campos incompletos',
          message: 'Por favor completa todos los campos',
        );
        return;
      }
      success = await authProvider.register(fullName, email, password, phone);
    }

    if (!mounted) return;

    if (success) {
      final userName = authProvider.currentUser?.fullName ?? 'Usuario';

      // Mostrar alert de bienvenida
      AlertService.showSuccess(
        context,
        title: '¡Bienvenido!',
        message: 'Hola $userName, tu sesión se ha iniciado correctamente',
      );

      // Navegar después de un pequeño delay para que se vea el alert
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AppShell()),
          );
        }
      });
    } else {
      AlertService.showError(
        context,
        title: 'Error de autenticación',
        message: authProvider.errorMessage ?? 'No se pudo iniciar sesión. Verifica tus credenciales',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MediControl',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Inicia sesión en tu cuenta' : 'Crea tu cuenta',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 35),
                  if (!isLogin)
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  if (!isLogin) const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  if (!isLogin) const SizedBox(height: 16),
                  if (!isLogin)
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleSubmit(authProvider),
                      child: Text(
                        authProvider.isLoading
                            ? 'Procesando...'
                            : isLogin
                                ? 'Iniciar sesión'
                                : 'Crear cuenta',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            setState(() => isLogin = !isLogin);
                            authProvider.clearError();
                            emailController.clear();
                            passwordController.clear();
                          },
                    child: Text(
                      isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
