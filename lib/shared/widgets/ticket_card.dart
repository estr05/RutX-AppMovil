import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

// =============================================================================
// TICKET CARD - Widget compartido para mostrar tickets de venta
// Usado por: VentaExitosaPage (post-venta) y VentaDetallePage (historial)
// =============================================================================

/// Widget de ticket de caja reutilizable.
///
/// Muestra: empresa, folio, fecha, cliente, renglones de articulos,
/// subtotal, IVA, total, y pie de ticket.
///
/// Se adapta via parametros opcionales:
/// - [esFolioReal]: colorea el folio verde (oficial) o amarillo (local)
/// - [estado]: si se provee, muestra el estado en el pie del ticket
/// - [headerSubtitle]: texto debajo del logo (ej: "Comprobante de venta")
class TicketCard extends StatelessWidget {
  final String clienteNombre;
  final String folioDisplay;
  final bool esFolioReal;
  final String dateTimeStr;
  final List<dynamic> detalles;
  final double subtotal;
  final double iva;
  final double totalConIva;
  final double abono;
  final String? estado;
  final String headerSubtitle;

  // Datos fiscales del emisor (opcionales)
  final String? emisorRfc;
  final String? emisorNombre;
  final String? sucursalDireccion;
  final String? sucursalPoblacion;

  const TicketCard({
    super.key,
    required this.clienteNombre,
    required this.folioDisplay,
    this.esFolioReal = true,
    required this.dateTimeStr,
    required this.detalles,
    required this.subtotal,
    required this.iva,
    required this.totalConIva,
    this.abono = 0,
    this.estado,
    this.headerSubtitle = 'Comprobante de venta',
    this.emisorRfc,
    this.emisorNombre,
    this.sucursalDireccion,
    this.sucursalPoblacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black08,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Borde serrado superior ──
          const _TicketEdge(top: true),

          // ── Contenido del ticket ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado empresa
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'TEKNOLOGIX',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headerSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const _DashedDivider(),
                const SizedBox(height: 12),

                // Datos fiscales del emisor (desde la sincronizacion matutina)
                if (emisorRfc != null && emisorRfc!.isNotEmpty) ...[
                  _TicketRow(label: 'RFC', value: emisorRfc!),
                  const SizedBox(height: 2),
                ],
                if (emisorNombre != null && emisorNombre!.isNotEmpty) ...[
                  _TicketRow(label: 'Empresa', value: emisorNombre!),
                  const SizedBox(height: 2),
                ],
                if ((sucursalDireccion != null &&
                        sucursalDireccion!.isNotEmpty) ||
                    (sucursalPoblacion != null &&
                        sucursalPoblacion!.isNotEmpty)) ...[
                  _TicketRow(
                    label: 'Direccion',
                    value: [
                      if (sucursalDireccion != null &&
                          sucursalDireccion!.isNotEmpty)
                        sucursalDireccion,
                      if (sucursalPoblacion != null &&
                          sucursalPoblacion!.isNotEmpty)
                        sucursalPoblacion,
                    ].join(', '),
                  ),
                  const SizedBox(height: 2),
                ],

                const SizedBox(height: 4),
                const _DashedDivider(),
                const SizedBox(height: 10),

                // Datos de la venta
                _TicketRow(
                  label: 'Folio',
                  value: folioDisplay,
                  valueColor:
                      esFolioReal ? AppTheme.statusGreen : AppTheme.statusAmber,
                ),
                const SizedBox(height: 4),
                _TicketRow(label: 'Fecha', value: dateTimeStr),
                const SizedBox(height: 4),
                _TicketRow(label: 'Cliente', value: clienteNombre),

                const SizedBox(height: 12),
                const _DashedDivider(),
                const SizedBox(height: 8),

                // Encabezado de columnas
                Row(
                  children: const [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'ARTICULO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        'QTY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'P/U',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        'IMPORTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const _DashedDivider(),
                const SizedBox(height: 6),

                // Renglones de articulos
                if (detalles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No hay detalles para esta venta.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ...detalles.map((d) => _buildItemRow(d)),

                const SizedBox(height: 10),
                const _DashedDivider(),
                const SizedBox(height: 12),

                // Subtotales
                _TotalsRow(
                  label: 'Subtotal (s/IVA)',
                  value: '\$${subtotal.toStringAsFixed(2)}',
                  bold: false,
                ),
                const SizedBox(height: 6),
                _TotalsRow(
                  label: 'IVA',
                  value: '\$${iva.toStringAsFixed(2)}',
                  bold: false,
                ),

                const SizedBox(height: 10),
                const _DashedDivider(),
                const SizedBox(height: 10),

                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '\$${totalConIva.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),

                if (abono > 0) ...[
                  const SizedBox(height: 10),
                  const _DashedDivider(),
                  const SizedBox(height: 10),
                  _TotalsRow(
                    label: 'Abono',
                    value: '\$${abono.toStringAsFixed(2)}',
                    bold: false,
                  ),
                  const SizedBox(height: 4),
                  _TotalsRow(
                    label: 'Saldo pendiente',
                    value: '\$${(totalConIva - abono).toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],

                const SizedBox(height: 16),
                const _DashedDivider(),
                const SizedBox(height: 14),

                // Pie del ticket
                Center(
                  child: Column(
                    children: [
                      if (estado != null) ...[
                        Text(
                          'Estado: ${estado!.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        estado != null
                            ? 'Este documento es de uso informativo.'
                            : 'Gracias por su compra!',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (estado == null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Este documento no es una factura fiscal.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Borde serrado inferior
          const _TicketEdge(top: false),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> d) {
    final nombre = (d['nombre'] as String?) ?? 'Producto';
    final qty = (d['unidades'] as int?) ?? 1;
    final precio = (d['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final importe = precio * qty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              nombre,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '\$${precio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '\$${importe.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS DEL TICKET
// =============================================================================

/// Fila de datos del ticket (Folio, Fecha, Cliente)
class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TicketRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila de totales (Subtotal, IVA)
class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalsRow({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Divisor punteado (efecto ticket)
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = AppTheme.borderLight
          ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(math.min(startX + dashWidth, size.width), 0),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Borde serrado del ticket (superior/inferior)
class _TicketEdge extends StatelessWidget {
  final bool top;

  const _TicketEdge({required this.top});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: CustomPaint(
        painter: _TicketEdgePainter(top: top),
        size: const Size(double.infinity, 12),
      ),
    );
  }
}

class _TicketEdgePainter extends CustomPainter {
  final bool top;

  const _TicketEdgePainter({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const radius = 6.0;
    const count = 20;
    final step = size.width / count;

    if (top) {
      path.moveTo(0, size.height);
      for (int i = 0; i < count; i++) {
        final cx = i * step + step / 2;
        path.arcTo(
          Rect.fromCircle(center: Offset(cx, size.height), radius: radius),
          math.pi,
          math.pi,
          false,
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < count; i++) {
        final cx = i * step + step / 2;
        path.arcTo(
          Rect.fromCircle(center: Offset(cx, 0), radius: radius),
          0,
          math.pi,
          false,
        );
      }
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }

    final bgPaint =
        Paint()
          ..color = AppTheme.backgroundColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
