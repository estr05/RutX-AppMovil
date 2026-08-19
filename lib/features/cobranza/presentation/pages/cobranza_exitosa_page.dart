import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';

class CobranzaExitosaPage extends StatelessWidget {
  final String clienteNombre;
  final double totalCobrado;
  final int documentosPagados;
  final String? folio;
  final int? doctoPvId;
  final bool esOffline;

  const CobranzaExitosaPage({
    super.key,
    required this.clienteNombre,
    required this.totalCobrado,
    required this.documentosPagados,
    this.folio,
    this.doctoPvId,
    this.esOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final NumberFormat currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        esOffline
                            ? AppTheme.alertWarningBg
                            : AppTheme.alertSuccessBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esOffline ? Icons.cloud_off : Icons.check_circle,
                    size: 64,
                    color:
                        esOffline ? AppTheme.statusAmber : AppTheme.statusGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  esOffline
                      ? 'Cobro guardado localmente'
                      : 'Cobro registrado exitosamente',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (esOffline) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Se sincronizara automaticamente cuando haya conexion',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black02,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _detalleRow('Cliente', clienteNombre, textTheme),
                      const SizedBox(height: 12),
                      _detalleRow(
                        'Total cobrado',
                        '\$${currencyFormat.format(totalCobrado)}',
                        textTheme,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      _detalleRow(
                        'Documentos pagados',
                        '$documentosPagados',
                        textTheme,
                      ),
                      if (folio != null) ...[
                        const SizedBox(height: 12),
                        _detalleRow('Folio', folio!, textTheme),
                      ],
                      if (doctoPvId != null) ...[
                        const SizedBox(height: 12),
                        _detalleRow('ID', '#$doctoPvId', textTheme),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('VOLVER A CREDITOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed:
                      () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('IR AL INICIO'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detalleRow(
    String label,
    String value,
    TextTheme textTheme, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppTheme.accentColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
