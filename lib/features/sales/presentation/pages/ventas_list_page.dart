import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/sync_result.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../shared/widgets/sale_card.dart';
import '../../../../shared/widgets/sale_utils.dart';
import '../../../../shared/widgets/no_venta_card.dart';
import '../../data/sales_repository.dart';
import 'venta_detalle_page.dart';
import 'no_venta_detalle_page.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';

class VentasListPage extends StatefulWidget {
  const VentasListPage({Key? key}) : super(key: key);

  @override
  State<VentasListPage> createState() => _VentasListPageState();
}

class _VentasListPageState extends State<VentasListPage> {
  List<VentaPendiente> _ventas = [];
  bool _isLoading = true;
  int _totalVentas = 0;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  Future<void> _loadVentas() async {
    await AppDatabase().initialize();
    
    // Intentar sincronizar primero para ver los errores
    final result = await SalesRepository().syncPendingSales();
    if (result is SyncFailure && mounted) {
      final friendlyMessage = _getFriendlyErrorMessage(result.mensaje);
      showErrorMessage(context, friendlyMessage);
    }

    // Obtenemos la fecha de hoy en formato YYYY-MM-DD
    final String hoy = DateTime.now().toIso8601String().substring(0, 10);
    
    final list = await AppDatabase().ventaDao.getDelDia(hoy);
    final resumen = await AppDatabase().ventaDao.getResumenDelDia(hoy);
    
    if (mounted) {
      setState(() {
        _ventas = list;
        _totalVentas = resumen['total_ventas'] ?? 0;
        _isLoading = false;
      });
    }
  }



  // ---------------------------------------------------------------------------
  // Traducción de Errores para el Usuario Final
  // ---------------------------------------------------------------------------
  String _getFriendlyErrorMessage(String technicalError) {
    if (technicalError.contains('API ERROR [401]')) {
      return 'Tu sesión ha caducado. Inicia sesión de nuevo.';
    } else if (technicalError.contains('NETWORK ERROR') || technicalError.contains('Sin conexión')) {
      return 'Venta guardada localmente. Se enviará automáticamente cuando recuperes la conexión.';
    } else if (technicalError.contains('API ERROR')) {
      // Mostrar el error real del backend para diagnóstico
      final backendDetail = technicalError.replaceFirst('API ERROR', '').trim();
      return 'Error del servidor: ${backendDetail.isNotEmpty ? backendDetail : "revise el backend"}';
    } else if (technicalError.contains('APP ERROR')) {
      return 'Algo salió mal en la aplicación. Intenta cerrarla y volverla a abrir.';
    }
    return 'No se pudo sincronizar la venta. Se seguirá intentando en segundo plano.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'Historial de Ventas',
      ),
      body: Column(
        children: [
          // Resumen card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Ventas', style: TextStyle(color: AppTheme.lightGrey, fontSize: 13)),
                      Text('$_totalVentas', style: const TextStyle(color: AppTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Monto Total', style: TextStyle(color: AppTheme.lightGrey, fontSize: 13)),
                      Text('\$${calcularTotalVentasConIVA(_ventas).toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _ventas.isEmpty
                    ? const Center(
                        child: Text('No hay ventas registradas hoy.', style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVentas,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ventas.length,
                          addRepaintBoundaries: true,
                          addAutomaticKeepAlives: false,
                          itemBuilder: (context, index) {
                            final venta = _ventas[index];
                            // Las NO VENTAS se muestran como resumen (sin ticket)
                            if (venta.esNoVenta) {
                              return NoVentaCard(
                                venta: venta,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NoVentaDetallePage(venta: venta),
                                    ),
                                  );
                                },
                              );
                            }
                            return SaleCard(
                              venta: venta,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VentaDetallePage(venta: venta),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
