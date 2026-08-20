import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/connection_state_service.dart';
import '../../data/summary_repository.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/local_storage.dart';

class CierreJornadaPage extends StatefulWidget {
  final int vendedorId;
  final VoidCallback onConfirmar;

  const CierreJornadaPage({
    super.key,
    required this.vendedorId,
    required this.onConfirmar,
  });

  @override
  State<CierreJornadaPage> createState() => _CierreJornadaPageState();
}

class _CierreJornadaPageState extends State<CierreJornadaPage> {
  final SummaryRepository _summaryRepo = SummaryRepository();
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final diaCerrado = await LocalStorage().getDiaCerrado();
    if (diaCerrado == today) {
      if (mounted) {
        setState(() {
          _errorMessage = 'La jornada de hoy ya fue cerrada.';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _summaryRepo.getDailySummary(DateTime.now());

      if (mounted) {
        if (result != null) {
          setState(() {
            _summaryData = result;
            _isLoading = false;
          });
        } else if (ConnectionStateService().currentState ==
            RutxConnectionState.offline) {
          setState(() {
            _errorMessage = 'sin_conexion';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'error_servidor';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'error_servidor';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(title: 'Cierre de Jornada'),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              )
              : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildSummaryState(),
    );
  }

  Widget _buildErrorState() {
    final bool isSinConexion = _errorMessage == 'sin_conexion';

    final String titulo =
        isSinConexion ? 'Sin conexion' : 'Error al obtener el resumen';
    final String mensaje =
        isSinConexion
            ? 'No hay conexion al servidor. Puedes cerrar la jornada de forma local y los datos se sincronizaran cuando se restablezca la conexion.'
            : 'El servidor respondio con un error. Verifica que el servicio este activo e intenta de nuevo.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.alertErrorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSinConexion
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: AppTheme.statusRed,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Solo mostrar el botón de cierre local si no hay conexión
            if (isSinConexion) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onConfirmar,
                  icon: const Icon(Icons.lock_rounded, color: Colors.white),
                  label: const Text(
                    'Cerrar jornada sin conexion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Botón Reintentar siempre visible
            TextButton.icon(
              onPressed: () async {
                if (_errorMessage.contains('ya fue cerrada')) {
                  await LocalStorage().clearDiaCerrado();
                }
                if (mounted) {
                  setState(() => _isLoading = true);
                  _fetchSummary();
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryState() {
    if (_summaryData == null) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final resumen = _summaryData ?? {};

    final int clientesVisitados = resumen['clientes_visitados'] ?? 0;
    final int efectividad = resumen['efectividad'] ?? 0;
    final int noVentas = resumen['no_ventas'] ?? 0;
    final int devoluciones = resumen['devoluciones_count'] ?? 0;

    final num dineroCaja = resumen['total_cierre'] ?? 0;
    final num cobros = resumen['cobrado'] ?? 0;
    // final num totalCredito = resumen['credito'] ?? 0;
    final num totalEfectivo =
        (resumen['contado'] ?? 0) + (resumen['cobrado_efectivo'] ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen de Ruta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa tus metricas antes de confirmar el cierre del dia.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildMetricCard(
            title: 'Indicadores',
            items: [
              _buildRowItem(
                'Clientes Visitados',
                clientesVisitados.toString(),
                Icons.people,
              ),
              _buildRowItem(
                'Efectividad (Ventas)',
                efectividad.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildRowItem(
                'No Ventas',
                noVentas.toString(),
                Icons.cancel,
                color: Colors.red,
              ),
              _buildRowItem(
                'Devoluciones',
                devoluciones.toString(),
                Icons.keyboard_return,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildMetricCard(
            title: 'Valores',
            items: [
              _buildRowItem(
                'Dinero en Caja',
                formatter.format(dineroCaja),
                Icons.account_balance_wallet,
                bold: true,
              ),
              _buildRowItem(
                'Cobros Realizados',
                formatter.format(cobros),
                Icons.monetization_on,
              ),
/*
              _buildRowItem(
                'Total Credito',
                formatter.format(totalCredito),
                Icons.credit_card,
              ),
*/
              _buildRowItem(
                'Total Efectivo',
                formatter.format(totalEfectivo),
                Icons.attach_money,
                color: Colors.green,
                bold: true,
              ),
            ],
          ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirmar Cierre'),
                      content: const Text(
                        'Estas seguro de que deseas cerrar la jornada? No podras registrar mas ventas hoy.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onConfirmar();
                          },
                          child: const Text(
                            'Cerrar Jornada',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
              );
            },
            icon: const Icon(Icons.lock, color: Colors.white),
            label: const Text(
              'CONFIRMAR CIERRE',
              style: TextStyle(
                color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.lightGrey),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildRowItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color:
                  bold
                      ? (color ?? AppTheme.textPrimary)
                      : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
