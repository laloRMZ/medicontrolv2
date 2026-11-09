# GUÍA DE ALERTAS POR PANTALLA - MediControl V2
## Cómo aplicar confirmaciones a todas las operaciones

---

## 1️⃣ APPOINTMENTS SCREEN (Citas)

### Ejemplo: Eliminar Cita

```dart
void deleteAppointmentWithConfirm(String appointmentId, String doctorName) {
  AlertService.confirmDelete(
    context,
    itemName: 'cita con $doctorName',
    onConfirm: () async {
      try {
        // Tu código para eliminar
        // await deleteAppointment(appointmentId);
        
        AlertService.operationComplete(
          context,
          operation: 'Cita eliminada',
        );
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'eliminar la cita',
          reason: e.toString(),
        );
      }
    },
  );
}
```

### Ejemplo: Cambiar Estado de Cita

```dart
void changeAppointmentStatusWithConfirm(
  String appointmentId,
  String currentStatus,
  String newStatus,
) {
  AlertService.confirmStatusChange(
    context,
    currentStatus: currentStatus,
    newStatus: newStatus,
    onConfirm: () async {
      try {
        // await updateStatus(appointmentId, newStatus);
        
        AlertService.operationComplete(
          context,
          operation: 'Estado actualizado a $newStatus',
        );
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'cambiar el estado',
        );
      }
    },
  );
}
```

---

## 2️⃣ EMERGENCY CONTACTS SCREEN (Contactos de Emergencia)

### Ejemplo: Eliminar Contacto

```dart
void deleteContactWithConfirm(String contactId, String contactName) {
  AlertService.confirmDelete(
    context,
    itemName: 'contacto $contactName',
    onConfirm: () async {
      try {
        // await deleteContact(contactId);
        
        AlertService.operationComplete(
          context,
          operation: 'Contacto eliminado',
        );
        _loadContacts(); // Recargar lista
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'eliminar el contacto',
        );
      }
    },
  );
}
```

### Ejemplo: Guardar Cambios en Contacto

```dart
void editContactWithConfirm(String contactId) {
  AlertService.confirmSave(
    context,
    onConfirm: () async {
      try {
        // await updateContact(contactId, newData);
        
        AlertService.operationComplete(
          context,
          operation: 'Contacto actualizado',
        );
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'actualizar el contacto',
        );
      }
    },
  );
}
```

---

## 3️⃣ MEDICAL RECORDS SCREEN (Registros Médicos)

### Ejemplo: Eliminar Registro Médico

```dart
void deleteMedicalRecordWithConfirm(String recordId, String recordType) {
  AlertService.confirmDelete(
    context,
    itemName: 'registro médico ($recordType)',
    onConfirm: () async {
      try {
        // await deleteRecord(recordId);
        
        AlertService.operationComplete(
          context,
          operation: 'Registro eliminado',
        );
        _loadRecords();
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'eliminar el registro',
        );
      }
    },
  );
}
```

### Ejemplo: Crear Registro Médico

```dart
void createMedicalRecordWithAlert() {
  try {
    // Validar datos
    if (titleController.text.isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campo requerido',
        message: 'El título es obligatorio',
      );
      return;
    }

    // Guardar registro
    // await saveMedicalRecord(...);

    AlertService.operationComplete(
      context,
      operation: 'Registro médico creado',
      onDismiss: () {
        clearForm();
        _loadRecords();
      },
    );
  } catch (e) {
    AlertService.operationFailed(
      context,
      operation: 'crear el registro',
    );
  }
}
```

---

## 4️⃣ PROFILE SCREEN (Perfil de Usuario)

### Ejemplo: Guardar Cambios de Perfil

```dart
void saveProfileChangesWithConfirm() {
  // Validar campos
  if (nameController.text.isEmpty) {
    AlertService.showWarning(
      context,
      title: 'Campo requerido',
      message: 'El nombre es obligatorio',
    );
    return;
  }

  AlertService.confirmSave(
    context,
    onConfirm: () async {
      try {
        // await updateProfile({
        //   'name': nameController.text,
        //   'phone': phoneController.text,
        //   'bloodType': selectedBloodType,
        // });

        AlertService.operationComplete(
          context,
          operation: 'Perfil actualizado',
          onDismiss: () {
            setState(() {}); // Refresh UI
          },
        );
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'actualizar el perfil',
        );
      }
    },
  );
}
```

### Ejemplo: Cambiar Contraseña

```dart
void changePasswordWithConfirm() {
  AlertService.confirmEdit(
    context,
    itemName: 'contraseña',
    onConfirm: () async {
      try {
        // await sendPasswordResetEmail(email);
        
        AlertService.operationComplete(
          context,
          operation: 'Email de recuperación enviado',
        );
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'enviar email de recuperación',
        );
      }
    },
  );
}
```

---

## 5️⃣ ADMIN DASHBOARD (Panel de Administrador)

### Ejemplo: Eliminar Usuario

```dart
void deleteUserWithConfirm(String userId, String userName) {
  AlertService.confirmDelete(
    context,
    itemName: 'usuario $userName',
    onConfirm: () async {
      try {
        // await deleteUser(userId);
        
        AlertService.operationComplete(
          context,
          operation: 'Usuario eliminado',
        );
        _loadUsers(); // Recargar lista
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'eliminar el usuario',
        );
      }
    },
  );
}
```

### Ejemplo: Cambiar Rol de Usuario

```dart
void changeUserRoleWithConfirm(String userId, String userName, String newRole) {
  AlertService.confirmStatusChange(
    context,
    currentStatus: 'Usuario Regular',
    newStatus: newRole,
    onConfirm: () async {
      try {
        // await updateUserRole(userId, newRole);
        
        AlertService.operationComplete(
          context,
          operation: 'Rol de $userName actualizado a $newRole',
        );
        _loadUsers();
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'cambiar el rol del usuario',
        );
      }
    },
  );
}
```

---

## 6️⃣ DOCTORS SCREEN (Doctores)

### Ejemplo: Eliminar Doctor

```dart
void deleteDoctorWithConfirm(String doctorId, String doctorName) {
  AlertService.confirmDelete(
    context,
    itemName: 'doctor $doctorName',
    onConfirm: () async {
      try {
        // await deleteDoctor(doctorId);
        
        AlertService.operationComplete(
          context,
          operation: 'Doctor eliminado',
        );
        _loadDoctors();
      } catch (e) {
        AlertService.operationFailed(
          context,
          operation: 'eliminar el doctor',
        );
      }
    },
  );
}
```

---

## 📋 RESUMEN DE ALERTAS DISPONIBLES

```dart
// Confirmaciones
AlertService.confirmDelete(context, itemName: '...', onConfirm: () {});
AlertService.confirmEdit(context, itemName: '...', onConfirm: () {});
AlertService.confirmStatusChange(context, 
  currentStatus: '...', 
  newStatus: '...', 
  onConfirm: () {}
);
AlertService.confirmSave(context, onConfirm: () {});

// Resultados de operación
AlertService.operationComplete(context, operation: '...');
AlertService.operationFailed(context, operation: '...', reason: '...');

// Alertas básicas
AlertService.showSuccess(context, title: '...', message: '...');
AlertService.showError(context, title: '...', message: '...');
AlertService.showWarning(context, title: '...', message: '...');
AlertService.showInfo(context, title: '...', message: '...');

// Toasts (notificaciones rápidas)
AlertService.showSuccessToast(context, 'Mensaje');
AlertService.showErrorToast(context, 'Mensaje');
AlertService.showWarningToast(context, 'Mensaje');
AlertService.showToast(context, 'Mensaje', bgColor: Colors.blue);
```

---

## 🎯 PATRÓN DE USO

```dart
// 1. Validar datos (si aplica)
if (validation_fails) {
  AlertService.showWarning(context, title: '...', message: '...');
  return;
}

// 2. Pedir confirmación
AlertService.confirmDelete(
  context,
  itemName: 'elemento',
  onConfirm: () async {
    try {
      // 3. Ejecutar operación
      await performOperation();
      
      // 4. Mostrar éxito
      AlertService.operationComplete(context, operation: 'Acción completada');
    } catch (e) {
      // 5. Mostrar error
      AlertService.operationFailed(context, operation: 'operación');
    }
  },
);
```

---

**Implementa estos patrones en cada pantalla para una experiencia de usuario consistente y segura.**
