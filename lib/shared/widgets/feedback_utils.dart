import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';
import 'app_notification_card.dart';

void showError(BuildContext context, AppError error, {VoidCallback? onRetry}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      content: AppNotificationCard(
        title: 'Error',
        message: error.mensajeUsuario,
        icon: Icons.error,
        iconColor: AppTheme.statusRed,
        backgroundColor: AppTheme.alertErrorBg,
        actionLabel: (error.esRecuperable && onRetry != null) ? 'REINTENTAR' : null,
        onAction: onRetry,
        onClose: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

void showErrorMessage(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      content: AppNotificationCard(
        title: 'Error',
        message: mensaje,
        icon: Icons.error,
        iconColor: AppTheme.statusRed,
        backgroundColor: AppTheme.alertErrorBg,
        onClose: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

void showSuccess(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: AppNotificationCard(
        message: mensaje,
        icon: Icons.check_circle,
        iconColor: AppTheme.statusGreen,
        backgroundColor: AppTheme.alertSuccessBg,
      ),
    ),
  );
}

void showInfo(BuildContext context, String mensaje, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: AppNotificationCard(
        message: mensaje,
        icon: Icons.info,
        iconColor: AppTheme.infoBlue,
        backgroundColor: AppTheme.infoBlueBg,
        actionLabel: actionLabel,
        onAction: onAction,
        onClose: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

void showWarning(
  BuildContext context,
  String mensaje, {
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 5),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: AppNotificationCard(
        title: title,
        message: mensaje,
        icon: Icons.warning_amber_rounded,
        iconColor: AppTheme.statusOrange,
        backgroundColor: AppTheme.alertWarningBg,
        actionLabel: actionLabel,
        onAction: onAction,
        onClose: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
