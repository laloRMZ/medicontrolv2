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

      // Mostrar alert de bienvenida y navegar automáticamente al dashboard sin requerir presionar OK
      AlertService.showSuccess(
        context,
        title: '¡Bienvenido!',
        message: 'Hola $userName, tu sesión se ha iniciado correctamente',
        autoDismiss: true,
        showOkButton: false,
        duration: const Duration(milliseconds: 1500),
        onDismiss: () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AppShell()),
              (route) => false,
            );
          }
        },
      );
    } else {
      AlertService.showError(
        context,
        title: 'Error de autenticación',
        message: authProvider.errorMessage ?? 'No se pudo iniciar sesión. Verifica tus credenciales',
      );
    }
  }

  void _toggleMode(AuthProvider authProvider, bool loginMode) {
    if (authProvider.isLoading || isLogin == loginMode) return;
    setState(() => isLogin = loginMode);
    authProvider.clearError();
    emailController.clear();
    passwordController.clear();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Stack(
            children: [
              // Fondo superior con gradiente médico
              Container(
                height: 290,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF00ACC1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          // Logo y título
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Color(0xFF1565C0),
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'MediControl',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLogin
                                ? 'Bienvenido de nuevo, cuida tu salud'
                                : 'Crea tu perfil médico en segundos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Tarjeta principal del formulario
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Selector Login / Registro
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _AuthModeTab(
                                          label: 'Iniciar sesión',
                                          selected: isLogin,
                                          onTap: () =>
                                              _toggleMode(authProvider, true),
                                        ),
                                      ),
                                      Expanded(
                                        child: _AuthModeTab(
                                          label: 'Registrarse',
                                          selected: !isLogin,
                                          onTap: () =>
                                              _toggleMode(authProvider, false),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Campos de registro con animación
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  child: isLogin
                                      ? const SizedBox.shrink()
                                      : Column(
                                          children: [
                                            TextField(
                                              controller: fullNameController,
                                              textInputAction:
                                                  TextInputAction.next,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: _buildInputDecoration(
                                                label: 'Nombre completo',
                                                hint: 'Ej. Ana López',
                                                icon: Icons.person_outline,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                          ],
                                        ),
                                ),

                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _buildInputDecoration(
                                    label: 'Correo electrónico',
                                    hint: 'correo@ejemplo.com',
                                    icon: Icons.email_outlined,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  textInputAction: isLogin
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  onSubmitted: (_) {
                                    if (isLogin && !authProvider.isLoading) {
                                      _handleSubmit(authProvider);
                                    }
                                  },
                                  decoration: _buildInputDecoration(
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  child: isLogin
                                      ? const SizedBox.shrink()
                                      : Column(
                                          children: [
                                            const SizedBox(height: 14),
                                            TextField(
                                              controller: phoneController,
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onSubmitted: (_) {
                                                if (!authProvider.isLoading) {
                                                  _handleSubmit(authProvider);
                                                }
                                              },
                                              decoration: _buildInputDecoration(
                                                label: 'Teléfono',
                                                hint: 'Ej. 5512345678',
                                                icon: Icons.phone_outlined,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),

                                const SizedBox(height: 24),

                                // Botón principal
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => _handleSubmit(authProvider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Procesando...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            isLogin
                                                ? 'Iniciar sesión'
                                                : 'Crear cuenta',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tus datos médicos están protegidos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
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
          );
        },
      ),
    );
  }
}

class _AuthModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
