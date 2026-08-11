import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Muestra el diálogo "Acerca de" de RutX.
void showAcercaDeDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AcercaDeDialog(),
  );
}

class _AcercaDeDialog extends StatelessWidget {
  const _AcercaDeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Stack(
        children: [
          // Recuadro principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black08,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de la app.
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'RX',
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'RutX - Teknologix 2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versión ${AppConstants.appVersion}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryColor60,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Vender organizado, es RutX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDarkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botón de cerrar (X) arriba a la derecha.
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              tooltip: 'Cerrar',
            ),
          ),
        ],
      ),
    );
  }
}
