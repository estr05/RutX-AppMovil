import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../shared/widgets/ticket_card.dart';
import '../../../../shared/widgets/sale_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';

class VentaDetallePage extends StatefulWidget {
  final VentaPendiente venta;

  const VentaDetallePage({super.key, required this.venta});

  @override
  State<VentaDetallePage> createState() => _VentaDetallePageState();
}

class _VentaDetallePageState extends State<VentaDetallePage> {
  String? _emisorRfc;
  String? _emisorNombre;
  String? _sucursalDireccion;
  String? _sucursalPoblacion;

  @override
  void initState() {
    super.initState();
    _cargarDatosFiscales();
  }

  Future<void> _cargarDatosFiscales() async {
    try {
      final db = AppDatabase();
      final emisor = await db.emisorDao.get();
      final sucursal = await db.sucursalDao.get();
      setState(() {
        _emisorRfc = emisor?.rfc;
        _emisorNombre = emisor?.nombreFiscal;
        if (sucursal != null) {
          final direccionParts = <String>[
            if (sucursal.calle.isNotEmpty) sucursal.calle,
            if (sucursal.numExterior.isNotEmpty) '#${sucursal.numExterior}',
            if (sucursal.numInterior.isNotEmpty) 'Int ${sucursal.numInterior}',
            if (sucursal.colonia.isNotEmpty) 'Col. ${sucursal.colonia}',
            if (sucursal.codigoPostal.isNotEmpty) 'CP ${sucursal.codigoPostal}',
          ];
          _sucursalDireccion = direccionParts.join(' ');
          _sucursalPoblacion = sucursal.poblacion;
        }
      });
    } catch (_) {
      // Sin datos fiscales disponibles, se omite la seccion
    }
  }

  /// Formatea la fecha y hora ISO a "DD/MM/YYYY HH:mm".
  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusColor.textColor(widget.venta.estado);

    final double subtotal = calcularSubtotal(widget.venta.detalles);
    final double iva = calcularIVA(widget.venta.detalles);
    final double totalConIva = subtotal + iva;
    final String dateTimeStr = _formatDateTime(widget.venta.fechaHora);

    final folioDisplay = widget.venta.folio ??
        widget.venta.folioLocal ??
        'REF-${widget.venta.ventaMovilId.length > 6 ? widget.venta.ventaMovilId.substring(widget.venta.ventaMovilId.length - 6).toUpperCase() : widget.venta.ventaMovilId.toUpperCase()}';
    final esFolioReal = widget.venta.folio != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'Detalle de Venta',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado de la Venta',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.venta.estado.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TicketCard(
                clienteNombre: widget.venta.clienteNombre,
                folioDisplay: folioDisplay,
                esFolioReal: esFolioReal,
                dateTimeStr: dateTimeStr,
                detalles: widget.venta.detalles,
                subtotal: subtotal,
                iva: iva,
                totalConIva: totalConIva,
                estado: widget.venta.estado,
                headerSubtitle: 'Detalle de Operacion',
                emisorRfc: _emisorRfc,
                emisorNombre: _emisorNombre,
                sucursalDireccion: _sucursalDireccion,
                sucursalPoblacion: _sucursalPoblacion,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
