import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/ticket_card.dart';
import '../../../../shared/widgets/sale_utils.dart';

class VentaExitosaPage extends StatelessWidget {
  final String clienteNombre;
  final double subtotal; // Total sin IVA
  final String ventaId;
  final String?
  folioMicrosip; // Folio real generado por Microsip (ej: V000000123)
  final String? folioLocal; // Folio provisional offline (ej: PRV-0000001)
  final bool isOnline;
  final List<Map<String, dynamic>> detalles;
  final double abono; // Abono en venta a credito

  // Datos fiscales del emisor (opcionales, se cargan desde DB)
  final String? emisorRfc;
  final String? emisorNombre;
  final String? sucursalDireccion;
  final String? sucursalPoblacion;

  const VentaExitosaPage({
    super.key,
    required this.clienteNombre,
    required this.subtotal,
    required this.ventaId,
    this.folioMicrosip,
    this.folioLocal,
    required this.isOnline,
    required this.detalles,
    this.abono = 0,
    this.emisorRfc,
    this.emisorNombre,
    this.sucursalDireccion,
    this.sucursalPoblacion,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    // Si hay folio real de Microsip PV, usarlo directamente (verde).
    // Si no, mostrar el folio provisional offline PRV-xxxxxxx (ambar).
    // Como ultimo recurso, una referencia local derivada del ID movil.
    final folioDisplay =
        folioMicrosip != null
            ? folioMicrosip! // ej: JA0000007 (folio oficial PV)
            : folioLocal != null
            ? folioLocal! // ej: PRV-0000001 (provisional)
            : 'REF-${ventaId.length >= 8 // referencia local
                    ? ventaId.substring(ventaId.length - 8).toUpperCase() : ventaId.toUpperCase()}';
    final esFolioReal = folioMicrosip != null;

    // Calculos de IVA usando utilidad compartida
    final double iva = calcularIVA(detalles);
    final double totalConIva = subtotal + iva;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header éxito ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  // Green Check Circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.alertSuccessBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.statusGreen,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isOnline ? 'Venta enviada' : 'Venta guardada',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (!isOnline)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.alertWarningBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.statusAmber),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.access_time,
                            color: AppTheme.statusAmber,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sin senal. Se enviara automaticamente al recuperar conexion.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.alertWarningText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── TICKET (widget compartido) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TicketCard(
                  clienteNombre: clienteNombre,
                  folioDisplay: folioDisplay,
                  esFolioReal: esFolioReal,
                  dateTimeStr: '$dateStr  $timeStr',
                  detalles: detalles,
                  subtotal: subtotal,
                  iva: iva,
                  totalConIva: totalConIva,
                  abono: abono,
                  headerSubtitle:
                      isOnline ? 'Comprobante de venta' : 'Venta pendiente',
                  emisorRfc: emisorRfc,
                  emisorNombre: emisorNombre,
                  sucursalDireccion: sucursalDireccion,
                  sucursalPoblacion: sucursalPoblacion,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botones ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Boton principal: Inicio
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, 'go_home');
                      },
                      icon: const Icon(
                        Icons.home_outlined,
                        color: AppTheme.textWhite,
                        size: 22,
                      ),
                      label: const Text(
                        'Inicio',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botones secundarios: Nueva venta | Historial
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, 'new_sale');
                            },
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Nueva venta',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.accentBorder,
                                width: 1.5,
                              ),
                              backgroundColor: AppTheme.accentBgLight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, 'go_history');
                            },
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Historial',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.accentBorder,
                                width: 1.5,
                              ),
                              backgroundColor: AppTheme.accentBgLight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
