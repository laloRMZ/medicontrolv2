import 'package:flutter/material.dart';

/// Servicio centralizado para mostrar alertas y notificaciones (usando solo Flutter nativo)
class AlertService {
  /// Alerta de éxito (Color verde)
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showDialog(context, title, message, Colors.green, onDismiss);
  }

  /// Alerta de error (Color rojo)
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    _showDialog(context, title, message, Colors.red, onDismiss);
  }

  /// Alerta de advertencia (Color naranja)
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    _showDialog(context, title, message, Colors.orange, onDismiss);
  }

  /// Alerta de información (Color azul)
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    _showDialog(context, title, message, Colors.blue, onDismiss);
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
            child: Text(confirmText),
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

  /// Método privado para mostrar diálogos
  static void _showDialog(
    BuildContext context,
    String title,
    String message,
    Color color,
    VoidCallback? onDismiss,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onDismiss?.call();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
