// EJEMPLO DE IMPLEMENTACIÓN - Appointments Screen con Alertas
// Copiar estos métodos a tu appointments_screen.dart

import '../services/alert_service.dart';

// ============================================================
// 1. CREAR CITA - Con alerta de éxito
// ============================================================
Future<void> createAppointmentWithAlert(BuildContext context) async {
  try {
    // Validar campos
    if (doctorController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        reasonController.text.isEmpty) {
      AlertService.showWarning(
        context,
        title: 'Campos Incompletos',
        message: 'Por favor completa todos los campos requeridos',
      );
      return;
    }

    // Validar que la razón tenga al menos 10 caracteres
    if (reasonController.text.length < 10) {
      AlertService.showWarning(
        context,
        title: 'Razón muy corta',
        message: 'La razón debe tener al menos 10 caracteres',
      );
      return;
    }

    // Crear la cita en Firebase
    // (Tu código de creación aquí)

    AlertService.showSuccess(
      context,
      title: '¡Cita Creada!',
      message: 'Tu cita con ${doctorController.text} el ${dateController.text} ha sido programada correctamente',
      duration: const Duration(seconds: 3),
      onDismiss: () {
        // Limpiar formulario
        doctorController.clear();
        dateController.clear();
        timeController.clear();
        reasonController.clear();

        // Recargar lista de citas
        _loadAppointments();
      },
    );
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error',
      message: 'No se pudo crear la cita. Verifica tu conexión e intenta de nuevo',
    );
  }
}

// ============================================================
// 2. CAMBIAR ESTADO DE CITA - Con alerta de éxito
// ============================================================
Future<void> updateAppointmentStatusWithAlert(
  BuildContext context,
  String appointmentId,
  String newStatus,
) async {
  try {
    // Actualizar en Firebase
    // (Tu código de actualización aquí)

    String statusLabel;
    switch (newStatus) {
      case 'pendiente':
        statusLabel = 'Pendiente';
        break;
      case 'en_proceso':
        statusLabel = 'En Proceso';
        break;
      case 'completada':
        statusLabel = 'Completada';
        break;
      default:
        statusLabel = newStatus;
    }

    AlertService.showSuccess(
      context,
      title: '¡Actualizado!',
      message: 'El estado de tu cita ahora es: $statusLabel',
      duration: const Duration(seconds: 2),
    );

    _loadAppointments(); // Recargar lista
  } catch (e) {
    AlertService.showErrorToast('Error al actualizar el estado');
  }
}

// ============================================================
// 3. CANCELAR CITA - Con confirmación
// ============================================================
void showCancelAppointmentDialog(
  BuildContext context,
  String appointmentId,
  String doctorName,
) {
  AlertService.showConfirm(
    context,
    title: '¿Cancelar Cita?',
    message: '¿Estás seguro que deseas cancelar la cita con $doctorName?',
    confirmText: 'Sí, cancelar',
    cancelText: 'No, mantener',
    onConfirm: () async {
      try {
        // Cancelar cita en Firebase
        // (Tu código aquí)

        AlertService.showSuccess(
          context,
          title: '¡Cita Cancelada',
          message: 'La cita ha sido cancelada correctamente',
          duration: const Duration(seconds: 2),
        );

        _loadAppointments(); // Recargar
      } catch (e) {
        AlertService.showErrorToast('Error al cancelar la cita');
      }
    },
  );
}

// ============================================================
// 4. ELIMINAR CITA - Con confirmación
// ============================================================
void showDeleteAppointmentDialog(
  BuildContext context,
  String appointmentId,
) {
  AlertService.showConfirm(
    context,
    title: '¿Eliminar Cita?',
    message: 'Esta acción no se puede deshacer',
    confirmText: 'Eliminar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      try {
        // Eliminar de Firebase
        // (Tu código aquí)

        AlertService.showSuccess(
          context,
          title: '¡Eliminada!',
          message: 'La cita ha sido eliminada permanentemente',
        );

        _loadAppointments();
      } catch (e) {
        AlertService.showErrorToast('Error al eliminar la cita');
      }
    },
  );
}

// ============================================================
// 5. APLICAR FILTROS - Con toast informativo
// ============================================================
void applyAppointmentFilters(
  BuildContext context,
  List<Appointment> appointments,
  String? selectedStatus,
  String? selectedDoctor,
) {
  List<Appointment> filtered = appointments;

  if (selectedStatus != null && selectedStatus.isNotEmpty) {
    filtered = filtered
        .where((apt) => apt.status.toLowerCase() == selectedStatus.toLowerCase())
        .toList();
  }

  if (selectedDoctor != null && selectedDoctor.isNotEmpty) {
    filtered = filtered
        .where((apt) => apt.doctorName.toLowerCase().contains(selectedDoctor.toLowerCase()))
        .toList();
  }

  // Mostrar toast con cantidad de resultados
  if (filtered.isEmpty) {
    AlertService.showToast(
      'No se encontraron citas con esos criterios',
      gravity: ToastGravity.TOP,
    );
  } else {
    AlertService.showSuccessToast(
      'Se encontraron ${filtered.length} cita(s)',
    );
  }

  // Actualizar la lista
  setState(() {
    displayedAppointments = filtered;
  });
}

// ============================================================
// 6. VALIDAR FECHA - Antes de crear
// ============================================================
bool validateAppointmentDate(BuildContext context, String dateString) {
  try {
    final selectedDate = DateTime.parse(dateString);
    final today = DateTime.now();

    if (selectedDate.isBefore(today)) {
      AlertService.showWarning(
        context,
        title: 'Fecha Inválida',
        message: 'No puedes agendar citas en fechas pasadas',
      );
      return false;
    }

    return true;
  } catch (e) {
    AlertService.showWarning(
      context,
      title: 'Formato de Fecha Inválido',
      message: 'Utiliza el formato: YYYY-MM-DD',
    );
    return false;
  }
}

// ============================================================
// 7. VALIDAR HORA - Antes de crear
// ============================================================
bool validateAppointmentTime(BuildContext context, String timeString) {
  try {
    final time = TimeOfDay(
      hour: int.parse(timeString.split(':')[0]),
      minute: int.parse(timeString.split(':')[1]),
    );

    // Validar que sea en horario de atención (08:00 - 20:00)
    if (time.hour < 8 || time.hour >= 20) {
      AlertService.showWarning(
        context,
        title: 'Hora Fuera de Rango',
        message: 'Las citas deben ser entre las 08:00 y las 20:00',
      );
      return false;
    }

    return true;
  } catch (e) {
    AlertService.showWarning(
      context,
      title: 'Formato de Hora Inválido',
      message: 'Utiliza el formato: HH:MM',
    );
    return false;
  }
}

// ============================================================
// 8. CARGAR CITAS - Con manejo de errores
// ============================================================
Future<void> loadAppointmentsWithAlert(BuildContext context) async {
  try {
    AlertService.showToast('Cargando citas...');

    // Cargar de Firebase
    // (Tu código aquí)

    setState(() {
      // Actualizar lista
    });

    if (appointments.isEmpty) {
      AlertService.showInfo(
        context,
        title: 'Sin Citas',
        message: 'Aún no has programado ninguna cita',
      );
    }
  } catch (e) {
    AlertService.showError(
      context,
      title: 'Error al Cargar',
      message: 'No se pudieron cargar tus citas. Verifica tu conexión',
    );
  }
}

// ============================================================
// 9. SINCRONIZAR CITAS - Con indicador
// ============================================================
Future<void> syncAppointmentsWithAlert(BuildContext context) async {
  try {
    AlertService.showToast('Sincronizando...');

    // Sincronizar con Firebase
    // (Tu código aquí)

    AlertService.showSuccessToast('Sincronización completada');
    _loadAppointments();
  } catch (e) {
    AlertService.showErrorToast('Error en la sincronización');
  }
}

// ============================================================
// 10. EXPORTAR CITAS - Con confirmación
// ============================================================
void showExportAppointmentsDialog(BuildContext context) {
  AlertService.showConfirm(
    context,
    title: '¿Exportar Citas?',
    message: 'Se exportarán todas tus citas en formato PDF',
    confirmText: 'Exportar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      try {
        // Código de exportación
        // (Tu código aquí)

        AlertService.showSuccess(
          context,
          title: '¡Exportado!',
          message: 'El archivo PDF se ha generado correctamente',
        );
      } catch (e) {
        AlertService.showErrorToast('Error al exportar');
      }
    },
  );
}

// ============================================================
// INTEGRACIÓN EN EL BUILD METHOD
// ============================================================
/*
Ejemplo de cómo integrar en tu ListView o botones:

ElevatedButton(
  onPressed: () => createAppointmentWithAlert(context),
  child: const Text('Crear Cita'),
),

PopupMenuButton(
  itemBuilder: (context) => [
    PopupMenuItem(
      child: const Text('Cancelar'),
      onTap: () => showCancelAppointmentDialog(context, appointmentId, doctorName),
    ),
    PopupMenuItem(
      child: const Text('Eliminar'),
      onTap: () => showDeleteAppointmentDialog(context, appointmentId),
    ),
  ],
),
*/
