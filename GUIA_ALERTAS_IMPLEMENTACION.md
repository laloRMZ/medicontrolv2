# GUÍA DE INTEGRACIÓN DE ALERTAS - MediControl V2
## Ejemplos de implementación de AlertService en diferentes pantallas

---

## 📌 RESUMEN RÁPIDO

**Librería usada:** `awesome_dialog` + `fluttertoast`  
**Servicio centralizado:** `lib/services/alert_service.dart`

### Tipos de Alertas Disponibles:

```dart
// Alertas grandes (con animación)
AlertService.showSuccess(context, title: '...', message: '...');
AlertService.showError(context, title: '...', message: '...');
AlertService.showWarning(context, title: '...', message: '...');
AlertService.showInfo(context, title: '...', message: '...');
AlertService.showConfirm(context, title: '...', message: '...',
  onConfirm: () { },
  onCancel: () { }
);

// Notificaciones rápidas (toast - abajo de pantalla)
AlertService.showToast('Mensaje');
AlertService.showSuccessToast('Éxito');
AlertService.showErrorToast('Error');
AlertService.showWarningToast('Advertencia');
```

---

## 1️⃣ LOGIN SCREEN - Alertas de Autenticación

### ✅ YA IMPLEMENTADO

El archivo `login_screen.dart` ya tiene:
- ✅ Alerta de éxito al iniciar sesión: `showSuccess()` con bienvenida personalizada
- ✅ Alerta de error al fallar login: `showError()`
- ✅ Alerta de campos incompletos: `showWarning()`

**Cambios realizados:**
```dart
import '../services/alert_service.dart';

// En el método _handleSubmit()
if (email.isEmpty || password.isEmpty) {
  AlertService.showWarning(
    context,
    title: 'Campos incompletos',
    message: 'Por favor completa el email y la contraseña',
  );
}

if (success) {
  final userName = authProvider.fullName ?? 'Usuario';
  AlertService.showSuccess(
    context,
    title: '¡Bienvenido!',
    message: 'Hola $userName, tu sesión se ha iniciado correctamente',
    onDismiss: () {
      Navigator.of(context).pushReplacement(...);
    },
  );
}
```

---

## 2️⃣ APPOINTMENTS SCREEN - Alertas de Citas

### 📋 Ejemplos para implementar:

#### A) Crear Cita - Éxito

```dart
import '../services/alert_service.dart';

// En el método que guarda la cita
Future<void> createAppointment() async {
  try {
    // ... código de creación ...
    
    if (!mounted) return;
    
    AlertService.showSuccess(
      context,
      title: '¡Cita Creada!',
      message: 'Tu cita con ${doctor.name} el $date se ha guardado correctamente',
      duration: const Duration(seconds: 3),
      onDismiss: () {
        _loadAppointments(); // Recargar lista
      },
    );
    
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error',
      message: 'No se pudo crear la cita. Intenta de nuevo',
    );
  }
}
```

#### B) Editar Estado de Cita

```dart
// Al cambiar estado (Pendiente → En Proceso → Completada)
Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
  try {
    // ... actualizar en Firebase ...
    
    AlertService.showSuccess(
      context,
      title: 'Estado Actualizado',
      message: 'La cita ahora está en estado: $newStatus',
      duration: const Duration(seconds: 2),
    );
  } catch (e) {
    AlertService.showErrorToast('Error al actualizar el estado');
  }
}
```

#### C) Cancelar Cita - Con Confirmación

```dart
// En el botón de cancelar
void showCancelConfirm(String appointmentId) {
  AlertService.showConfirm(
    context,
    title: '¿Cancelar cita?',
    message: '¿Estás seguro que deseas cancelar esta cita?',
    confirmText: 'Sí, cancelar',
    cancelText: 'No, mantener',
    onConfirm: () async {
      try {
        // ... código de cancelación ...
        AlertService.showSuccess(
          context,
          title: 'Cita Cancelada',
          message: 'La cita ha sido cancelada correctamente',
        );
      } catch (e) {
        AlertService.showError(
          context,
          title: 'Error',
          message: 'No se pudo cancelar la cita',
        );
      }
    },
    onCancel: () {
      // El diálogo se cierra automáticamente
    },
  );
}
```

#### D) Filtrar Citas - Toast Informativo

```dart
// Después de filtrar
void applyFilters() {
  // ... aplicar filtros ...
  
  AlertService.showToast(
    'Se encontraron ${filteredAppointments.length} citas',
    gravity: ToastGravity.TOP,
  );
}
```

---

## 3️⃣ EMERGENCY CONTACTS - Alertas de Contactos

### 📋 Ejemplos para implementar:

#### A) Agregar Contacto - Éxito

```dart
import '../services/alert_service.dart';

Future<void> addEmergencyContact() async {
  try {
    // ... validar campos ...
    // ... guardar en Firebase ...
    
    AlertService.showSuccess(
      context,
      title: '¡Contacto Agregado!',
      message: 'Se ha guardado $contactName como contacto de emergencia',
      onDismiss: () {
        clearForm();
        _loadContacts();
      },
    );
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error',
      message: 'No se pudo guardar el contacto. Intenta de nuevo',
    );
  }
}
```

#### B) Eliminar Contacto - Con Confirmación

```dart
void showDeleteContactConfirm(String contactId, String contactName) {
  AlertService.showConfirm(
    context,
    title: '¿Eliminar contacto?',
    message: '¿Deseas eliminar a $contactName de tus contactos de emergencia?',
    confirmText: 'Eliminar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      try {
        // ... código para eliminar ...
        AlertService.showSuccess(
          context,
          title: 'Contacto Eliminado',
          message: '$contactName ha sido removido de tus contactos',
        );
      } catch (e) {
        AlertService.showErrorToast('Error al eliminar el contacto');
      }
    },
  );
}
```

#### C) Editar Contacto - Éxito

```dart
Future<void> updateEmergencyContact(String contactId) async {
  try {
    // ... validar y actualizar ...
    
    AlertService.showSuccess(
      context,
      title: '¡Actualizado!',
      message: 'La información del contacto se ha actualizado correctamente',
      duration: const Duration(seconds: 2),
    );
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error',
      message: 'No se pudo actualizar el contacto',
    );
  }
}
```

---

## 4️⃣ MEDICAL RECORDS - Alertas de Registros Médicos

### 📋 Ejemplos para implementar:

#### A) Crear Registro Médico

```dart
import '../services/alert_service.dart';

Future<void> addMedicalRecord() async {
  try {
    // ... validar campos ...
    // ... guardar en Firebase ...
    
    AlertService.showSuccess(
      context,
      title: '¡Registro Guardado!',
      message: 'Tu registro médico se ha guardado correctamente',
      onDismiss: () {
        _loadMedicalRecords();
        clearForm();
      },
    );
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error al Guardar',
      message: 'No se pudo guardar el registro médico',
    );
  }
}
```

#### B) Eliminar Registro - Con Confirmación

```dart
void showDeleteRecordConfirm(String recordId, String recordType) {
  AlertService.showConfirm(
    context,
    title: '¿Eliminar registro?',
    message: 'Este $recordType será eliminado permanentemente',
    confirmText: 'Eliminar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      try {
        // ... código de eliminación ...
        AlertService.showSuccess(
          context,
          title: '¡Eliminado!',
          message: 'El registro médico ha sido eliminado',
        );
      } catch (e) {
        AlertService.showErrorToast('Error al eliminar');
      }
    },
  );
}
```

#### C) Exportar Registro - Toast Simple

```dart
void exportMedicalRecord(String recordId) {
  try {
    // ... código de exportación ...
    AlertService.showSuccessToast('Registro exportado correctamente');
  } catch (e) {
    AlertService.showErrorToast('Error al exportar');
  }
}
```

---

## 5️⃣ PROFILE SCREEN - Alertas de Perfil

### 📋 Ejemplos para implementar:

#### A) Guardar Cambios de Perfil

```dart
import '../services/alert_service.dart';

Future<void> saveProfileChanges() async {
  try {
    // ... validar datos ...
    // ... actualizar en Firebase ...
    
    AlertService.showSuccess(
      context,
      title: '¡Perfil Actualizado!',
      message: 'Tus datos personales se han guardado correctamente',
      duration: const Duration(seconds: 2),
      onDismiss: () {
        // Refrescar datos en pantalla
        setState(() {});
      },
    );
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error',
      message: 'No se pudo actualizar tu perfil. Intenta de nuevo',
    );
  }
}
```

#### B) Validación de Campos

```dart
void validateProfileFields() {
  if (nameController.text.isEmpty) {
    AlertService.showWarning(
      context,
      title: 'Campo Requerido',
      message: 'El nombre es obligatorio',
    );
    return;
  }
  
  if (phoneController.text.length < 10) {
    AlertService.showWarning(
      context,
      title: 'Teléfono Inválido',
      message: 'El teléfono debe tener al menos 10 dígitos',
    );
    return;
  }
  
  // Si todo es válido, guardar
  saveProfileChanges();
}
```

#### C) Cambiar Contraseña - Con Confirmación

```dart
void showChangePasswordDialog() {
  AlertService.showConfirm(
    context,
    title: '¿Cambiar contraseña?',
    message: 'Se te enviará un correo para cambiar tu contraseña',
    confirmText: 'Sí, enviar email',
    cancelText: 'Cancelar',
    onConfirm: () async {
      try {
        // ... enviar email de recuperación ...
        AlertService.showSuccess(
          context,
          title: '¡Email Enviado!',
          message: 'Revisa tu correo para cambiar tu contraseña',
        );
      } catch (e) {
        AlertService.showErrorToast('Error al enviar el email');
      }
    },
  );
}
```

---

## 6️⃣ ADMIN DASHBOARD - Alertas de Administrador

### 📋 Ejemplos para implementar:

#### A) Cambiar Rol de Usuario

```dart
void showChangeUserRoleDialog(String userId, String userName) {
  AlertService.showConfirm(
    context,
    title: '¿Cambiar rol?',
    message: '¿Deseas cambiar el rol de $userName a administrador?',
    confirmText: 'Sí, cambiar',
    cancelText: 'No',
    onConfirm: () async {
      try {
        // ... actualizar rol en Firebase ...
        AlertService.showSuccess(
          context,
          title: '¡Rol Actualizado!',
          message: 'El rol de $userName ha sido cambiado',
        );
      } catch (e) {
        AlertService.showErrorToast('Error al cambiar el rol');
      }
    },
  );
}
```

#### B) Acción Crítica - Alerta de Peligro

```dart
void showDeleteUserWarning(String userId, String userName) {
  AlertService.showWarning(
    context,
    title: '⚠️ Acción Crítica',
    message: 'Estás a punto de eliminar la cuenta de $userName. Esta acción no se puede deshacer.',
  );
}
```

---

## 7️⃣ ERRORES DE CONEXIÓN - Alertas Globales

### 📋 Ejemplos para implementar en cualquier pantalla:

#### A) Error de Conexión a Internet

```dart
void handleConnectionError() {
  AlertService.showError(
    context,
    title: 'Sin Conexión',
    message: 'Verifica tu conexión a internet e intenta de nuevo',
  );
}
```

#### B) Error de Firebase

```dart
void handleFirebaseError(String errorCode) {
  String message;
  
  switch (errorCode) {
    case 'user-not-found':
      message = 'El usuario no existe';
      break;
    case 'wrong-password':
      message = 'Contraseña incorrecta';
      break;
    case 'email-already-in-use':
      message = 'Este correo ya está registrado';
      break;
    default:
      message = 'Ocurrió un error. Intenta de nuevo';
  }
  
  AlertService.showError(
    context,
    title: 'Error de Autenticación',
    message: message,
  );
}
```

#### C) Timeout de Operación

```dart
void handleTimeout() {
  AlertService.showWarning(
    context,
    title: 'Tiempo Agotado',
    message: 'La operación tardó demasiado. Por favor intenta de nuevo',
  );
}
```

---

## 🔧 CHECKLIST DE IMPLEMENTACIÓN

### Por pantalla, implementar alertas en estos eventos:

#### ✅ Login Screen
- [x] Campos vacíos (warning)
- [x] Login exitoso (success)
- [x] Login fallido (error)
- [ ] Registro exitoso (success)
- [ ] Registro fallido (error)

#### Appointments Screen
- [ ] Crear cita (success)
- [ ] Error al crear (error)
- [ ] Editar cita (success)
- [ ] Cancelar cita (confirm → success)
- [ ] Eliminar cita (confirm → success)
- [ ] Filtrar citas (toast info)

#### Emergency Contacts
- [ ] Agregar contacto (success)
- [ ] Error al agregar (error)
- [ ] Editar contacto (success)
- [ ] Eliminar contacto (confirm → success)
- [ ] Campos inválidos (warning)

#### Medical Records
- [ ] Crear registro (success)
- [ ] Actualizar registro (success)
- [ ] Eliminar registro (confirm → success)
- [ ] Exportar registro (toast success)

#### Profile Screen
- [ ] Guardar cambios (success)
- [ ] Validación de campos (warning)
- [ ] Error al guardar (error)
- [ ] Cambiar contraseña (confirm)

#### Admin Dashboard
- [ ] Cambiar rol (confirm → success)
- [ ] Eliminar usuario (warning)
- [ ] Acción completada (success)

---

## 💾 INSTALACIÓN DE DEPENDENCIAS

Si aún no lo has hecho, ejecuta:

```bash
flutter pub get
```

Esto instalará:
- `awesome_dialog: ^3.2.0`
- `fluttertoast: ^8.2.3`

---

## 📝 NOTAS IMPORTANTES

1. **Siempre importar:** `import '../services/alert_service.dart';`
2. **BuildContext:** Asegúrate de que el context sea válido (usa `if (!mounted) return;`)
3. **Duración:** Los alertas grandes tienen duración predeterminada, puedes cambiarla
4. **Posición de Toast:** Usa `gravity: ToastGravity.TOP` o `.BOTTOM` según necesites
5. **Colores:** Los colores están predefinidos pero puedes personalizarlos

---

## 🎨 PERSONALIZACIÓN (Opcional)

### Cambiar colores de alertas:

```dart
// En alert_service.dart, modificar showToast():
static void showSuccessToast(String message) {
  showToast(
    message,
    bgColor: const Color(0xFF4CAF50), // Tu color aquí
    textColor: Colors.white,
  );
}
```

### Cambiar animaciones:

```dart
// En los diálogos, cambiar AnimType:
animType: AnimType.scale,  // Cambiar a: slideInUp, slideInDown, etc.
```

---

**Última actualización:** Noviembre 2026

**Estado:** Listo para implementar

