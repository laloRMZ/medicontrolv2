import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

/// Servicio centralizado para mostrar alertas y notificaciones
class AlertService {
  /// Alerta de éxito (Color verde)
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 3),
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        onDismiss?.call();
        Navigator.of(context).pop();
      },
      dismissOnTouchOutside: true,
      autoHide: duration,
    ).show();
  }

  /// Alerta de error (Color rojo)
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        onDismiss?.call();
        Navigator.of(context).pop();
      },
      dismissOnTouchOutside: true,
    ).show();
  }

  /// Alerta de advertencia (Color naranja)
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        onDismiss?.call();
        Navigator.of(context).pop();
      },
      dismissOnTouchOutside: true,
    ).show();
  }

  /// Alerta de información (Color azul)
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        onDismiss?.call();
        Navigator.of(context).pop();
      },
      dismissOnTouchOutside: true,
    ).show();
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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnCancelOnPress: () {
        onCancel?.call();
        Navigator.of(context).pop();
      },
      btnOkOnPress: () {
        onConfirm.call();
        Navigator.of(context).pop();
      },
      btnCancelText: cancelText,
      btnOkText: confirmText,
    ).show();
  }

  /// Toast simple en la base (Notificación temporal corta)
  static void showToast(String message,
      {ToastPosition position = ToastPosition.bottom,
      Color? bgColor,
      Color? textColor}) {
    showToastWidget(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      position: position,
      duration: const Duration(seconds: 2),
    );
  }

  /// Toast de éxito (Verde)
  static void showSuccessToast(String message) {
    showToast(
      message,
      bgColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
    );
  }

  /// Toast de error (Rojo)
  static void showErrorToast(String message) {
    showToast(
      message,
      bgColor: const Color(0xFFF44336),
      textColor: Colors.white,
    );
  }

  /// Toast de advertencia (Naranja)
  static void showWarningToast(String message) {
    showToast(
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
    required DialogType dialogType,
    VoidCallback? onOk,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        onOk?.call();
        Navigator.of(context).pop();
      },
      dismissOnTouchOutside: true,
    ).show();
  }
}
