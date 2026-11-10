import 'package:flutter/material.dart';

/// Servicio centralizado para mostrar alertas y notificaciones (usando solo Flutter nativo)
class AlertService {
  /// Alerta de éxito (Color verde)
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
    bool autoDismiss = false,
    bool? showOkButton,
  }) {
    _showDialog(
      context,
      title,
      message,
      Colors.green,
      onDismiss,
      duration: duration,
      autoDismiss: autoDismiss,
      showOkButton: showOkButton,
    );
  }

  /// Alerta de error (Color rojo)
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 3),
    bool autoDismiss = false,
    bool? showOkButton,
  }) {
    _showDialog(
      context,
      title,
      message,
      Colors.red,
      onDismiss,
      duration: duration,
      autoDismiss: autoDismiss,
      showOkButton: showOkButton,
    );
  }

  /// Alerta de advertencia (Color naranja)
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 3),
    bool autoDismiss = false,
    bool? showOkButton,
  }) {
    _showDialog(
      context,
      title,
      message,
      Colors.orange,
      onDismiss,
      duration: duration,
      autoDismiss: autoDismiss,
      showOkButton: showOkButton,
    );
  }

  /// Alerta de información (Color azul)
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 3),
    bool autoDismiss = false,
    bool? showOkButton,
  }) {
    _showDialog(
      context,
      title,
      message,
      Colors.blue,
      onDismiss,
      duration: duration,
      autoDismiss: autoDismiss,
      showOkButton: showOkButton,
    );
  }

  /// Diálogo de confirmación (Sí/No)
  static void showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Sí',
    String cancelText = 'No',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.pop(context);
            },
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              onConfirm.call();
              Navigator.pop(context);
            },
            child: Text(confirmText, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  /// Toast simple usando SnackBar nativo
  static void showToast(
    BuildContext context,
    String message, {
    Color? bgColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Toast de éxito (Verde)
  static void showSuccessToast(BuildContext context, String message) {
    showToast(
      context,
      message,
      bgColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
    );
  }

  /// Toast de error (Rojo)
  static void showErrorToast(BuildContext context, String message) {
    showToast(
      context,
      message,
      bgColor: const Color(0xFFF44336),
      textColor: Colors.white,
    );
  }

  /// Toast de advertencia (Naranja)
  static void showWarningToast(BuildContext context, String message) {
    showToast(
      context,
      message,
      bgColor: const Color(0xFFFF9800),
      textColor: Colors.white,
    );
  }

  /// Diálogo personalizado con solo OK
  static void showCustom(
    BuildContext context, {
    required String title,
    required String message,
    Color color = Colors.blue,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              onOk?.call();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FUNCIONES HELPER PARA OPERACIONES COMUNES
  // ============================================================

  /// Confirmación para editar un elemento
  static void confirmEdit(
    BuildContext context, {
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    showConfirm(
      context,
      title: '¿Editar $itemName?',
      message: 'Confirma que deseas editar esta información',
      confirmText: 'Sí, editar',
      cancelText: 'Cancelar',
      onConfirm: onConfirm,
    );
  }

  /// Confirmación para eliminar un elemento
  static void confirmDelete(
    BuildContext context, {
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    showConfirm(
      context,
      title: '¿Eliminar $itemName?',
      message: 'Esta acción no se puede deshacer',
      confirmText: 'Sí, eliminar',
      cancelText: 'Cancelar',
      onConfirm: onConfirm,
    );
  }

  /// Confirmación para cambiar estado
  static void confirmStatusChange(
    BuildContext context, {
    required String currentStatus,
    required String newStatus,
    required VoidCallback onConfirm,
  }) {
    showConfirm(
      context,
      title: '¿Cambiar estado?',
      message: 'Cambiar de "$currentStatus" a "$newStatus"',
      confirmText: 'Sí, cambiar',
      cancelText: 'Cancelar',
      onConfirm: onConfirm,
    );
  }

  /// Confirmación para guardar cambios
  static void confirmSave(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    showConfirm(
      context,
      title: '¿Guardar cambios?',
      message: 'Confirma que deseas guardar estos cambios',
      confirmText: 'Sí, guardar',
      cancelText: 'Cancelar',
      onConfirm: onConfirm,
    );
  }

  /// Alerta de operación completada
  static void operationComplete(
    BuildContext context, {
    required String operation,
    VoidCallback? onDismiss,
  }) {
    showSuccess(
      context,
      title: '✅ Completado',
      message: '$operation se ha completado correctamente',
      onDismiss: onDismiss,
    );
  }

  /// Alerta de operación fallida
  static void operationFailed(
    BuildContext context, {
    required String operation,
    String? reason,
  }) {
    showError(
      context,
      title: '❌ Error',
      message: 'No se pudo completar $operation${reason != null ? ': $reason' : ''}',
    );
  }

  /// Método privado para mostrar diálogos
  static void _showDialog(
    BuildContext context,
    String title,
    String message,
    Color color,
    VoidCallback? onDismiss, {
    Duration duration = const Duration(seconds: 2),
    bool autoDismiss = false,
    bool? showOkButton,
  }) {
    bool isDismissed = false;

    void handleDismiss(BuildContext dialogContext) {
      if (isDismissed) return;
      isDismissed = true;
      if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      }
      onDismiss?.call();
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        if (autoDismiss) {
          Future.delayed(duration, () {
            if (dialogContext.mounted) {
              handleDismiss(dialogContext);
            }
          });
        }

        final shouldShowOk = showOkButton ?? !autoDismiss;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          icon: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                      ? Icons.error
                      : color == Colors.orange
                          ? Icons.warning
                          : Icons.info,
              color: color,
              size: 36,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: shouldShowOk
              ? [
                  TextButton(
                    onPressed: () => handleDismiss(dialogContext),
                    child: const Text('OK', style: TextStyle(fontSize: 16)),
                  ),
                ]
              : null,
        );
      },
    ).then((_) {
      if (!isDismissed) {
        isDismissed = true;
        onDismiss?.call();
      }
    });
  }
}

