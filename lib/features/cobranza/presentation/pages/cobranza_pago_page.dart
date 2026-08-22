import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../../credito/data/credito_repository.dart';
import '../../data/cobranza_repository.dart';
import '../../../../core/database/entities/cobranza_pendiente_entity.dart';
import 'cobranza_exitosa_page.dart';

class CobranzaPagoPage extends StatefulWidget {
  final int clienteId;
  final String clienteNombre;
  final double saldoPendiente;

  const CobranzaPagoPage({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
    required this.saldoPendiente,
  });

  @override
  State<CobranzaPagoPage> createState() => _CobranzaPagoPageState();
}

class _CobranzaPagoPageState extends State<CobranzaPagoPage> {
  final CreditoRepository _creditoRepo = CreditoRepository();
  final CobranzaRepository _cobranzaRepo = CobranzaRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  List<Map<String, dynamic>> _documentos = [];
  bool _isLoadingDocs = true;
  bool _isSubmitting = false;

  // clave: indice del documento, valor: monto a pagar
  final Map<int, double> _montosPagar = {};
  final Map<int, bool> _seleccionados = {};
  final Map<int, TextEditingController> _amountControllers = {};

  // Formas de pago disponibles
  static const List<Map<String, dynamic>> _formasCobro = [
    {'id': 67, 'nombre': 'EFECTIVO', 'icono': Icons.money},
    {'id': 2845, 'nombre': 'TARJETA', 'icono': Icons.credit_card},
    {'id': 3702, 'nombre': 'TRANSFERENCIA', 'icono': Icons.account_balance},
  ];

  int? _formaCobroId;
  final TextEditingController _montoPagoController = TextEditingController();
  double _lastMontoPago = 0;
  int _vendedorId = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _onMontoChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
    if (parsed != _lastMontoPago) {
      _lastMontoPago = parsed;
      setState(() {});
    }
  }

  Future<void> _init() async {
    final vId = await LocalStorage().getVendedorId();
    _vendedorId = vId ?? 0;
    await _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    setState(() => _isLoadingDocs = true);
    final docs = await _creditoRepo.getDocumentosCliente(widget.clienteId);
    if (mounted) {
      setState(() {
        _documentos = docs;
        _isLoadingDocs = false;
        for (int i = 0; i < docs.length; i++) {
          _seleccionados[i] = false;
          _montosPagar[i] = 0.0;
        }
        _initControllers();
      });
    }
  }

  void _initControllers() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    _amountControllers.clear();
    for (int i = 0; i < _documentos.length; i++) {
      final saldo =
          (_documentos[i]['saldo_pendiente'] as num?)?.toDouble() ?? 0;
      _amountControllers[i] = TextEditingController(
        text: saldo.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    _montoPagoController.dispose();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalSeleccionado {
    double total = 0;
    for (final entry in _seleccionados.entries) {
      if (entry.value) {
        total += _montosPagar[entry.key] ?? 0;
      }
    }
    return total;
  }

  double get _montoPagoIngresado => _lastMontoPago;

  bool get _puedeCobrar {
    return _formaCobroId != null &&
        _seleccionados.values.any((v) => v) &&
        _totalSeleccionado > 0 &&
        _montoPagoIngresado > 0 &&
        _totalSeleccionado == _montoPagoIngresado &&
        !_isSubmitting;
  }

  Future<void> _procesarCobro() async {
    if (!_puedeCobrar) return;

    setState(() => _isSubmitting = true);

    final documentosCobrar = <Map<String, dynamic>>[];
    for (final entry in _seleccionados.entries) {
      if (entry.value) {
        final doc = _documentos[entry.key];
        documentosCobrar.add({
          'docto_pv_original_id': doc['docto_pv_original_id'] as int? ?? 0,
          'importe_pagado': _montosPagar[entry.key] ?? 0,
        });
      }
    }

    final pagos = <Map<String, dynamic>>[
      {'forma_cobro_id': _formaCobroId, 'importe': _montoPagoIngresado},
    ];

    final cobranza = CobranzaPendiente(
      vendedorId: _vendedorId,
      clienteId: widget.clienteId,
      clienteNombre: widget.clienteNombre,
      fechaHora: DateTime.now().toIso8601String(),
      totalCobrado: _montoPagoIngresado,
      pagos: pagos,
      documentos: documentosCobrar,
    );

    try {
      final result = await _cobranzaRepo.insertCobranza(cobranza);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => CobranzaExitosaPage(
                  clienteNombre: widget.clienteNombre,
                  totalCobrado: _montoPagoIngresado,
                  documentosPagados: documentosCobrar.length,
                  folio: result['folio'] as String?,
                  doctoPvId: result['docto_pv_id'] as int?,
                  esOffline: result['success'] != true,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('[Cobranza] Error técnico: $e');
        showErrorMessage(
          context,
          'No se pudo registrar el cobro. Intenta de nuevo o guárdalo offline.',
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: RutxAppBar(
        title: 'Cobranza',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textWhite),
            onPressed: _cargarDocumentos,
          ),
        ],
      ),
      body:
          _isLoadingDocs
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              )
              : _documentos.isEmpty
              ? _buildEmptyState(textTheme, colorScheme)
              : _buildContent(textTheme, colorScheme),
      bottomNavigationBar:
          _isLoadingDocs || _documentos.isEmpty
              ? null
              : _buildBottomBar(textTheme),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme, ColorScheme colorScheme) {
    return Center(
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
            'No hay documentos pendientes',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.clienteNombre} no tiene creditos pendientes',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TextTheme textTheme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClienteHeader(textTheme),
          const SizedBox(height: 20),
          _buildDocumentosSection(textTheme, colorScheme),
          const SizedBox(height: 20),
          _buildFormaPagoSection(textTheme),
          const SizedBox(height: 20),
          _buildResumen(textTheme),
        ],
      ),
    );
  }

  Widget _buildClienteHeader(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.alertWarningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.statusAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.clienteNombre.isNotEmpty
                    ? widget.clienteNombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clienteNombre,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo total: \$${_currencyFormat.format(widget.saldoPendiente)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.categoryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentosSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOCUMENTOS A PAGAR',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          addRepaintBoundaries: true,
          itemCount: _documentos.length,
          itemBuilder: (context, i) => _buildDocumentoCard(i, textTheme),
        ),
      ],
    );
  }

  Widget _buildDocumentoCard(int index, TextTheme textTheme) {
    final doc = _documentos[index];
    final folio = doc['folio'] as String? ?? 'S/N';
    final saldo = (doc['saldo_pendiente'] as num?)?.toDouble() ?? 0;
    final isSelected = _seleccionados[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLightBg : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.infoBlue : AppTheme.borderLight,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppTheme.accentColor,
                  onChanged: (val) {
                    setState(() {
                      _seleccionados[index] = val ?? false;
                      if (val == true) {
                        _montosPagar[index] = saldo;
                      } else {
                        _montosPagar[index] = 0.0;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Folio: $folio',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${_currencyFormat.format(saldo)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 36),
                Text('Monto a pagar:', style: textTheme.bodySmall),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  height: 36,
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '\$ ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.accentColor),
                      ),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    controller: _amountControllers[index]!,
                    onChanged: (val) {
                      final monto =
                          double.tryParse(val.replaceAll(',', '')) ?? 0;
                      setState(() => _montosPagar[index] = monto);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormaPagoSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORMA DE PAGO',
          style: textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _formasCobro.map((fc) {
                final id = fc['id'] as int;
                final isActive = _formaCobroId == id;
                return GestureDetector(
                  onTap: () => setState(() => _formaCobroId = id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? AppTheme.accentBgLight
                              : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isActive
                                ? AppTheme.accentColor
                                : AppTheme.borderLight,
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fc['icono'] as IconData,
                          size: 18,
                          color:
                              isActive
                                  ? AppTheme.accentColor
                                  : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fc['nombre'] as String,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                isActive
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_formaCobroId != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Monto recibido:', style: textTheme.bodyMedium),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                height: 40,
                child: TextField(
                  controller: _montoPagoController,
                  onChanged: _onMontoChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '\$ ',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.accentColor),
                    ),
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResumen(TextTheme textTheme) {
    final diferencia = _totalSeleccionado - _montoPagoIngresado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _resumenRow(
            'Total documentos',
            '\$${_currencyFormat.format(_totalSeleccionado)}',
            textTheme,
            false,
          ),
          const SizedBox(height: 6),
          _resumenRow(
            'Total pagado',
            '\$${_currencyFormat.format(_montoPagoIngresado)}',
            textTheme,
            false,
          ),
          const SizedBox(height: 6),
          if (diferencia != 0)
            _resumenRow(
              'Diferencia',
              '\$${_currencyFormat.format(diferencia.abs())}',
              textTheme,
              true,
            ),
        ],
      ),
    );
  }

  Widget _resumenRow(
    String label,
    String value,
    TextTheme textTheme,
    bool isError,
  ) {
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
            fontWeight: FontWeight.w800,
            color: isError ? AppTheme.statusRed : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black08,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _puedeCobrar ? _procesarCobro : null,
          icon:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.payment),
          label: Text(_isSubmitting ? 'PROCESANDO...' : 'COBRAR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            disabledBackgroundColor: AppTheme.accentColor.withValues(
              alpha: 0.4,
            ),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
