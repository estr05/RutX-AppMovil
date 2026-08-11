import 'package:flutter/material.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/sale_utils.dart';
import '../../data/summary_repository.dart';
import 'end_of_day_splash_page.dart';
import '../../../../features/sales/data/sales_repository.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../../../shared/widgets/acerca_de_dialog.dart';
import '../../../../core/network/connection_state_service.dart';
import '../../../../core/network/sync_result.dart';
import '../../../sync/presentation/widgets/re_descarga_sheet.dart';
import 'cierre_jornada_page.dart';

class ResumenDiaPage extends StatefulWidget {
  const ResumenDiaPage({Key? key}) : super(key: key);

  @override
  State<ResumenDiaPage> createState() => _ResumenDiaPageState();
}

class _ResumenDiaPageState extends State<ResumenDiaPage> {
  final SalesRepository _salesRepository = SalesRepository();
  final SummaryRepository _summaryRepository = SummaryRepository();

  List<VentaPendiente> _ventas = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isClosing = false;

  int _pendientesCount = 0;

  // Variables de métricas
  int _totalVentas = 0;
  int _piezasVendidas = 0;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }



  Future<void> _loadVentas() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      await db.initialize();

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final list = await db.ventaDao.getDelDia(today);
      final resumen = await db.ventaDao.getResumenDelDia(today);

      int pendientes = 0;
      for (final v in list) {
        if (v.estado == 'pendiente' || v.estado == 'error') {
          pendientes++;
        }
      }

      if (mounted) {
        setState(() {
          _ventas = list;
          _pendientesCount = pendientes;
          _totalVentas = (resumen['total_ventas'] as num?)?.toInt() ?? 0;
          _piezasVendidas = (resumen['piezas_vendidas'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSync() async {
    setState(() => _isSyncing = true);
    final result = await _salesRepository.syncPendingSales();
    await _loadVentas();
    if (mounted) {
      setState(() => _isSyncing = false);
      if (_pendientesCount > 0) {
        final detalle = result is SyncFailure ? result.mensaje : null;
        showWarning(
          context,
          detalle ?? 'Haz la sincronización final antes de cerrar para no perder datos.',
          title: 'Tienes $_pendientesCount ${_pendientesCount == 1 ? "venta pendiente" : "ventas pendientes"}',
          actionLabel: 'REINTENTAR',
          onAction: _handleSync,
        );
      } else {
        showSuccess(context, 'Sincronización completada');
      }
    }
  }

  /// Abre el flujo de "Descargar nuevamente" (análisis + descarga incremental).
  void _handleDescargarNuevamente() {
    if (_isSyncing || _isClosing) return;
    if (ConnectionStateService().isOffline) {
      showWarning(
        context,
        'No puedes descargar datos sin conexión a internet. Conéctate a una red e intenta de nuevo.',
        title: 'Sin conexión',
      );
      return;
    }
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReDescargaSheet(),
    ).then((resultado) {
      if (resultado == true) {
        _loadVentas();
        showSuccess(context, 'Datos descargados correctamente');
      }
    });
  }

  void _clearOldSales() async {
    if (_isClosing) return;
    final db = AppDatabase();
    await db.initialize();
    await db.ventaDao.deleteAll();
    await _loadVentas();
  }

  void _handleCerrarJornada() async {
    if (_isClosing) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final diaCerrado = await LocalStorage().getDiaCerrado();
    if (diaCerrado == today) {
      if (mounted) {
        final entrar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Jornada ya cerrada'),
            content: const Text('La jornada de hoy ya fue cerrada. Si es una prueba, puedes borrar el registro y entrar.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await LocalStorage().clearDiaCerrado();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Entrar de todas formas'),
              ),
            ],
          ),
        );
        if (entrar != true) return;
      } else {
        return;
      }
    }
    final vendedorId = await LocalStorage().getVendedorId() ?? 0;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CierreJornadaPage(
            vendedorId: vendedorId,
            onConfirmar: _executeCerrarJornada,
          ),
        ),
      );
    }
  }

  void _executeCerrarJornada() async {
    if (_isClosing) return;
    try {
      setState(() => _isClosing = true);
      SyncResult? resultado;
      if (_pendientesCount > 0) {
        setState(() => _isSyncing = true);
        resultado = await _salesRepository.syncPendingSales();
        await _loadVentas();
        setState(() => _isSyncing = false);
      }

      // 2. Si TODAVÍA quedan pendientes, BLOQUEAR el cierre
      if (_pendientesCount > 0) {
        if (mounted) {
          final detalle = resultado is SyncFailure ? resultado.mensaje : null;
          showWarning(
            context,
            detalle ?? 'No puedes cerrar la jornada. Haz la sincronización final antes de cerrar para no perder datos.',
            title: 'Tienes $_pendientesCount ${_pendientesCount == 1 ? "venta pendiente" : "ventas pendientes"}',
            actionLabel: 'REINTENTAR',
            onAction: _handleSync,
          );
        }
        return;
      }

      showInfo(context, 'Procesando cierre de jornada...');

      final db = AppDatabase();
      await db.initialize();

      final result = await _summaryRepository.sendClosingData(
        fecha: DateTime.now(),
        ventas: _ventas,
        totalEfectivo: calcularTotalVentasConIVA(_ventas),
      );
      if (result['hay_diferencia'] == true && mounted) {
        showInfo(context, result['mensaje'] as String? ?? 'Cierre local completado (servidor no disponible)');
      }

      // 3. Marcar el día como cerrado ANTES de limpiar datos
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await LocalStorage().setDiaCerrado(today);

      // 4. Ahora sí, limpiar y desloguear
      await db.limpiarDatosDelDia();
      await LocalStorage().clearSession();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (context, animation, secondaryAnimation) => const EndOfDaySplashPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Transición que "se despliega" expandiendo desde el centro (Scale + Fade)
              var curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCirc);
              return ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
                  child: child,
                ),
              );
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosing = false);
        showError(context, AppError(
          mensajeUsuario: 'Error al cerrar jornada. Intenta de nuevo.',
          esRecuperable: false,
        ));
      }
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black02,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'Ajustes y Cierre',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card: Descargar nuevamente
                  _buildActionCard(
                    icon: Icons.refresh,
                    iconColor: AppTheme.accentColor,
                    iconBg: AppTheme.accent10,
                    title: 'Descargar nuevamente',
                    subtitle: 'Vuelve a descargar clientes, productos y configuración desde el servidor.',
                    onTap: (_isSyncing || _isClosing) ? null : _handleDescargarNuevamente,
                  ),
                  const SizedBox(height: 16),
                  // Card: Acerca de
                  _buildActionCard(
                    icon: Icons.info_outline,
                    iconColor: AppTheme.primaryColor,
                    iconBg: AppTheme.infoBlueBg,
                    title: 'Acerca de',
                    subtitle: 'Versión de la aplicación, información de licencia y datos del desarrollador.',
                    onTap: () => showAcercaDeDialog(context),
                  ),

                ],
              ),
            ),
      // Bottom Sticky Area: Sincronización y Cierre
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20).copyWith(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 20,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary05,
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSyncing)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pendientesCount > 0 ? _handleSync : null,
                  icon: Icon(
                    _pendientesCount > 0 ? Icons.sync : Icons.check_circle_outline,
                    color: _pendientesCount > 0 ? AppTheme.accentColor : AppTheme.textSecondary,
                  ),
                  label: Text(
                    _pendientesCount > 0 ? 'Sincronización final' : 'Todo sincronizado',
                    style: TextStyle(
                      color: _pendientesCount > 0 ? AppTheme.accentColor : AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _pendientesCount > 0 ? AppTheme.accent50 : AppTheme.lightGrey,
                      width: 1.5,
                    ),
                    backgroundColor: _pendientesCount > 0 ? AppTheme.accent10 : AppTheme.backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClosing ? null : _handleCerrarJornada,
                icon: _isClosing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.surfaceColor,
                        ),
                      )
                    : const Icon(
                        Icons.exit_to_app,
                        color: AppTheme.surfaceColor,
                      ),
                label: Text(
                  _isClosing ? 'Cerrando...' : 'Cerrar jornada',
                  style: const TextStyle(
                    color: AppTheme.surfaceColor,
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
            TextButton(
              onPressed: _clearOldSales,
              child: Text(
                'Borrar ventas viejas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
