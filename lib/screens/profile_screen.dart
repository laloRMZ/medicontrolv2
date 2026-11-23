import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/profile_pdf_service.dart';
import '../widgets/info_card.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'support_chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isGeneratingPdf = false;
  bool _isUpdatingPhoto = false;

  ImageProvider? _resolveProfileImage(String? rawImage) {
    if (rawImage == null || rawImage.trim().isEmpty) return null;
    if (rawImage.startsWith('data:image')) {
      final commaIndex = rawImage.indexOf(',');
      if (commaIndex != -1) {
        try {
          final Uint8List bytes = base64Decode(rawImage.substring(commaIndex + 1));
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
      return NetworkImage(rawImage);
    }
    return null;
  }

  Future<void> _pickProfilePhotoFromGallery(AuthProvider authProvider) async {
    if (_isUpdatingPhoto) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;

      setState(() => _isUpdatingPhoto = true);
      final bytes = await picked.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final ok = await authProvider.updateProfileImage(dataUri);
      if (!mounted) return;

      if (ok) {
        AlertService.showSuccess(
          context,
          title: 'Foto actualizada',
          message: 'Tu foto de perfil se guardó correctamente',
          autoDismiss: true,
          showOkButton: false,
          duration: const Duration(milliseconds: 1400),
        );
      } else {
        AlertService.operationFailed(
          context,
          operation: 'actualizar la foto de perfil',
          reason: authProvider.errorMessage ?? 'Error desconocido',
        );
      }
    } catch (e) {
      if (mounted) {
        AlertService.operationFailed(
          context,
          operation: 'seleccionar la imagen',
          reason: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPhoto = false);
      }
    }
  }

  Future<void> _showPhotoOptions(
    AuthProvider authProvider,
    bool hasPhoto,
  ) async {
    if (!hasPhoto) {
      await _pickProfilePhotoFromGallery(authProvider);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickProfilePhotoFromGallery(authProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Quitar foto actual'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                setState(() => _isUpdatingPhoto = true);
                final ok = await authProvider.updateProfileImage(null);
                if (!mounted) return;
                setState(() => _isUpdatingPhoto = false);
                if (!ok) {
                  AlertService.operationFailed(
                    context,
                    operation: 'quitar la foto de perfil',
                    reason: authProvider.errorMessage ?? 'Error desconocido',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printMedicalProfile(AppUser user) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final safeName = user.fullName.trim().isEmpty
          ? 'usuario'
          : user.fullName.trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.layoutPdf(
        name: 'perfil_medico_$safeName.pdf',
        onLayout: (_) => ProfilePdfService.buildMedicalProfilePdf(user),
      );
    } catch (e) {
      if (mounted) {
        AlertService.operationFailed(
          context,
          operation: 'generar el PDF del perfil médico',
          reason: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final profileImageProvider = _resolveProfileImage(user?.profileImage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
        actions: [
          if (user != null)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Imprimir / Exportar PDF',
              onPressed:
                  _isGeneratingPdf ? null : () => _printMedicalProfile(user),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Perfil',
            onPressed: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              // Si los datos fueron actualizados, forzar reconstrucción
              if (updated == true && mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: user == null || _isUpdatingPhoto
                        ? null
                        : () => _showPhotoOptions(
                              authProvider,
                              profileImageProvider != null,
                            ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          backgroundImage: profileImageProvider,
                          child: _isUpdatingPhoto
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : profileImageProvider == null
                                  ? Text(
                                      (user?.fullName.isNotEmpty ?? false)
                                          ? user!.fullName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: user == null || _isUpdatingPhoto
                        ? null
                        : () => _pickProfilePhotoFromGallery(authProvider),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Cambiar foto de perfil'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.fullName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATOS PERSONALES
                  const Text(
                    'Datos Personales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    icon: Icons.person,
                    label: 'Nombre',
                    value: user?.fullName ?? '---',
                  ),
                  InfoCard(
                    icon: Icons.email,
                    label: 'Email',
                    value: user?.email ?? '---',
                  ),
                  InfoCard(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: (user?.phone.isEmpty ?? true) ? '---' : user!.phone,
                  ),
                  const SizedBox(height: 24),

                  // DATOS MÉDICOS
                  const Text(
                    'Datos Médicos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    icon: Icons.bloodtype,
                    label: 'Tipo de Sangre',
                    value: (user?.medicalData.bloodType.isEmpty ?? true)
                        ? '---'
                        : user!.medicalData.bloodType,
                  ),
                  InfoCard(
                    icon: Icons.warning,
                    label: 'Alergias',
                    value: (user?.medicalData.allergies.isEmpty ?? true)
                        ? '---'
                        : user!.medicalData.allergies,
                  ),
                  InfoCard(
                    icon: Icons.notes,
                    label: 'Notas Médicas',
                    value: (user?.medicalData.notes.isEmpty ?? true)
                        ? '---'
                        : user!.medicalData.notes,
                  ),
                  const SizedBox(height: 24),

                  // CONTACTO DE EMERGENCIA
                  const Text(
                    'Contacto de Emergencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    icon: Icons.contact_emergency,
                    label: 'Nombre del Contacto',
                    value: (user?.medicalData.emergencyContactName.isEmpty ?? true)
                        ? '---'
                        : user!.medicalData.emergencyContactName,
                  ),
                  InfoCard(
                    icon: Icons.phone_in_talk,
                    label: 'Teléfono de Emergencia',
                    value:
                        (user?.medicalData.emergencyContactPhone.isEmpty ?? true)
                            ? '---'
                            : user!.medicalData.emergencyContactPhone,
                  ),
                  const SizedBox(height: 16),

                  if (user != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingPdf
                            ? null
                            : () => _printMedicalProfile(user),
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.print),
                        label: Text(
                          _isGeneratingPdf
                              ? 'Generando PDF...'
                              : 'Imprimir / Exportar Perfil Médico (PDF)',
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ROL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Cuenta',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              user?.role.name.toUpperCase() ?? 'USER',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CONFIGURACIÓN
                  const Text(
                    'Configuración',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificaciones'),
                      trailing: Switch(value: true, onChanged: (_) {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Privacidad y seguridad'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ),
                  if (!authProvider.isAdmin) _buildSupportCard(context),

                  const SizedBox(height: 24),

                  // BOTÓN LOGOUT
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.headset_mic),
          title: const Text('Soporte técnico'),
          subtitle: const Text('Chat en vivo y ayuda'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SupportChatScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AlertService.showConfirm(
      context,
      title: '¿Cerrar sesión?',
      message: 'Se cerrará tu sesión en MediControl',
      confirmText: 'Sí, cerrar sesión',
      cancelText: 'Cancelar',
      onConfirm: () {
        final navigator = Navigator.of(context);
        final authProvider = context.read<AuthProvider>();
        // Cerrar el dialog primero con un pequeño delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            authProvider.logout();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      },
    );
  }
}
