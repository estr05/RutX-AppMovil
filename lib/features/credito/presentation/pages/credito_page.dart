import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/credito_repository.dart';
import '../../../cobranza/presentation/pages/cobranza_pago_page.dart';

class CreditoPage extends StatefulWidget {
  const CreditoPage({super.key});

  @override
  State<CreditoPage> createState() => _CreditoPageState();
}

class _CreditoPageState extends State<CreditoPage> {
  final CreditoRepository _repo = CreditoRepository();
  List<Map<String, dynamic>> _creditos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreditos();
  }

  Future<void> _loadCreditos({bool forceRefresh = false}) async {
    setState(() => _isLoading = !forceRefresh);
    final vendedorId = await LocalStorage().getVendedorId();
    final list = await _repo.getPedidosCredito(
      vendedorId: vendedorId,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _creditos = list;
        _isLoading = false;
      });
    }
  }

  Color _pctColor(double usado) {
    return usado > 80
        ? AppTheme.statusRed
        : usado > 50
        ? AppTheme.statusOrange
        : AppTheme.statusGreen;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 16,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            child: Text(
              'Créditos Pendientes',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    )
                    : _creditos.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.statusGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin créditos pendientes',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _loadCreditos(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        addRepaintBoundaries: true,
                        itemCount: _creditos.length,
                        itemBuilder: (context, index) {
                          final c = _creditos[index];
                          final nombre = c['nombre'] as String? ?? 'Cliente';
                          final saldo =
                              (c['saldo_pendiente'] as num?)?.toDouble() ?? 0.0;
                          final limite =
                              (c['limite_credito'] as num?)?.toDouble() ?? 0.0;
                          final usado =
                              (c['porcentaje_usado'] as num?)?.toDouble() ??
                              0.0;
                          final docsPend =
                              c['documentos_pendientes'] as int? ?? 0;
                          final diasAtraso = c['dias_atraso'] as int? ?? 0;
                          final pctColor = _pctColor(usado);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.borderLight,
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.black02,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (diasAtraso > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.alertErrorBg,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$diasAtraso ${diasAtraso == 1 ? 'día' : 'días'}',
                                          style: TextStyle(
                                            color: AppTheme.statusRed,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _Metric(
                                      label: 'Saldo',
                                      value: '\$${saldo.toStringAsFixed(2)}',
                                      isPrimary: true,
                                    ),
                                    _Metric(
                                      label: 'Límite',
                                      value: '\$${limite.toStringAsFixed(2)}',
                                    ),
                                    _Metric(label: 'Docs.', value: '$docsPend'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (usado / 100).clamp(0.0, 1.0),
                                    backgroundColor: AppTheme.lightGrey,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      pctColor,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${usado.toStringAsFixed(1)}% usado',
                                  style: TextStyle(
                                    color: pctColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => CobranzaPagoPage(
                                                clienteId:
                                                    c['cliente_id'] as int,
                                                clienteNombre: nombre,
                                                saldoPendiente: saldo,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text(
                                      'COBRAR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.accentColor,
                                      side: BorderSide(
                                        color: AppTheme.accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _Metric({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color:
                  isPrimary
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
