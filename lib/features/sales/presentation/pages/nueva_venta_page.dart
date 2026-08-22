import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/connectivity_mixin.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../core/database/entities/producto_entity.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../core/database/entities/forma_cobro_entity.dart';
import '../../data/sales_repository.dart';
import '../../../../shared/widgets/sale_utils.dart';
import '../../../../shared/widgets/stock_label.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'venta_exitosa_page.dart';

class NuevaVentaPage extends StatefulWidget {
  final Cliente cliente;
  const NuevaVentaPage({super.key, required this.cliente});

  @override
  State<NuevaVentaPage> createState() => _NuevaVentaPageState();
}

class _NuevaVentaPageState extends State<NuevaVentaPage>
    with SingleTickerProviderStateMixin, ConnectivityMixin {
  final SalesRepository _salesRepository = SalesRepository();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  final Map<String, int> _letterIndices = {};
  String _currentLetter = '';
  bool _isDragging = false;

  String _searchQuery = '';
  List<Producto> _productos = [];
  final Map<int, int> _cart = {};
  bool _isLoading = true;

  // Resolución dinámica de Forma de Cobro: evita IDs harcodeadas (67, 71, etc.)
  // Si _formaCobroId es 0, el Sincronizador Backend le asigna automáticamente la DefaultFormaCobroId configurada en el servidor.
  int _formaCobroId = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Repaint bottom sticky button and tabs count
    });
    setupConnectivity();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = AppDatabase();
    await db.initialize();
    // Carga perezosa: primeros 100 productos
    final list = await db.productDao.getFirst(100);
    list.sort((a, b) => a.nombre.compareTo(b.nombre));

    // Cargar catálogo dinámico de Formas de Cobro desde SQLite
    final formas = await db.formaCobroDao.getAll();
    final formaContado = formas.cast<FormaCobro?>().firstWhere(
      (f) => f != null && f.esContado,
      orElse: () => null,
    );

    // Determinar ID dinámico de contado o fallback a 0 (Servidor Backend)
    final idDinamico = formaContado?.formaCobroId ?? (formas.isNotEmpty ? formas.first.formaCobroId : 0);

    if (mounted) {
      setState(() {
        _productos = list;
        _formaCobroId = idDinamico;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    disposeConnectivity();
    _tabController.dispose();
    super.dispose();
  }

  void _calculateLetterIndices(List<Producto> filteredList) {
    _letterIndices.clear();
    for (int i = 0; i < filteredList.length; i++) {
      String firstLetter =
          filteredList[i].nombre.isNotEmpty
              ? filteredList[i].nombre[0].toUpperCase()
              : '';
      if (firstLetter.isNotEmpty && !_letterIndices.containsKey(firstLetter)) {
        _letterIndices[firstLetter] = i;
      }
    }
  }

  void _scrollToLetter(String letter) {
    if (_letterIndices.containsKey(letter)) {
      int index = _letterIndices[letter]!;
      double offset = index * 90.0;

      if (_scrollController.hasClients) {
        if (offset > _scrollController.position.maxScrollExtent) {
          offset = _scrollController.position.maxScrollExtent;
        }
        _scrollController.jumpTo(offset);
      }
    }
  }

  void _handleSliderDrag(double dy, double maxHeight) {
    if (maxHeight <= 0) return;
    int index = ((dy / maxHeight) * _alphabet.length).floor();
    index = index.clamp(0, _alphabet.length - 1);
    String letter = _alphabet[index];

    if (_currentLetter != letter || !_isDragging) {
      setState(() {
        _currentLetter = letter;
        _isDragging = true;
      });
      _scrollToLetter(letter);
    }
  }

  Widget _buildAlphabetSidebar() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onVerticalDragDown:
                (d) => _handleSliderDrag(
                  d.localPosition.dy,
                  constraints.maxHeight,
                ),
            onVerticalDragUpdate:
                (d) => _handleSliderDrag(
                  d.localPosition.dy,
                  constraints.maxHeight,
                ),
            onVerticalDragEnd: (_) => setState(() => _isDragging = false),
            onVerticalDragCancel: () => setState(() => _isDragging = false),
            child: Container(
              width: 32,
              height: constraints.maxHeight,
              color: Colors.transparent,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _alphabet.map((letter) {
                        bool isSelected = _isDragging && _currentLetter == letter;
                        return Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLetterIndicatorOverlay() {
    return Center(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _currentLetter,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Producto> _getFilteredProducts() {
    final list = _productos.where((p) {
      return p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clave.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    _calculateLetterIndices(list);
    return list;
  }

  Producto? _findProduct(int id) {
    for (final p in _productos) {
      if (p.articuloId == id) return p;
    }
    return null;
  }

  double _getCartTotal() {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final prod = _findProduct(id);
      if (prod == null) return;
      total += prod.precio * qty;
    });
    return total;
  }

  /// Precio con impuestos COMPUESTOS del producto (del sync), con fallback.
  double _precioConImpuesto(Producto p) => precioConImpuestoProducto(p);

  /// Total del carrito exhibido con impuestos (solo visual, no viaja a PV).
  double _getCartTotalConImpuestos() {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final prod = _findProduct(id);
      if (prod == null) return;
      total += _precioConImpuesto(prod) * qty;
    });
    return total;
  }

  int _getCartDistinctCount() {
    return _cart.length;
  }

  void _addToCart(int id) {
    final prod = _findProduct(id);
    if (prod == null) return;
    final enCarrito = _cart[id] ?? 0;

    // Validación de existencia: no se puede vender más de lo que lleva
    // el almacén del vendedor (RUTXALMACEN01).
    if (!puedeAgregarUnidad(producto: prod, enCarrito: enCarrito)) {
      showWarning(
        context,
        enCarrito > 0
            ? 'Solo hay ${formatearExistencia(prod.existencias)} disponible y ya llevas $enCarrito en el pedido.'
            : 'Este producto no tiene existencia disponible en tu almacén.',
        title: 'Existencia insuficiente',
      );
      return;
    }

    setState(() {
      _cart[id] = enCarrito + 1;
    });
  }

  void _removeFromCart(int id) {
    if (!_cart.containsKey(id)) return;
    setState(() {
      if (_cart[id] == 1) {
        _cart.remove(id);
      } else {
        _cart[id] = _cart[id]! - 1;
      }
    });
  }

  void _deleteFromCart(int id) {
    setState(() {
      _cart.remove(id);
    });
  }

  void _showUndoSnackBar(int savedId, int savedQty) {
    showInfo(
      context,
      'Artículo descartado del carrito',
      actionLabel: 'DESHACER',
      onAction: () {
        setState(() {
          _cart[savedId] = savedQty;
        });
      },
    );
  }

  Future<double?> _showAbonoDialog(BuildContext context, double total) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool quiereAbonar = false;

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    '¿El cliente va abonar?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total de venta: \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setDialogState(() => quiereAbonar = true);
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            label: const Text('SI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  quiereAbonar
                                      ? AppTheme.statusGreen
                                      : AppTheme.accentBgLight,
                              foregroundColor:
                                  quiereAbonar
                                      ? AppTheme.textWhite
                                      : AppTheme.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
                              Navigator.pop(ctx, 0.0);
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 20),
                            label: const Text('NO'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  !quiereAbonar
                                      ? AppTheme.statusRed
                                      : AppTheme.textSecondary,
                              side: BorderSide(
                                color:
                                    !quiereAbonar
                                        ? AppTheme.statusRed
                                        : AppTheme.borderLight,
                                width: 1.5,
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
                  if (quiereAbonar) ...[
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '¿Cuánto va abonar?',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa un monto';
                          final val = double.tryParse(v.replaceAll(',', '.'));
                          if (val == null || val <= 0) return 'Monto inválido';
                          if (val > total) {
                            return 'El abono no puede exceder el total';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final val = double.tryParse(
                              amountController.text.replaceAll(',', '.'),
                            );
                            if (val == null) return;
                            Navigator.pop(ctx, val);
                          }
                        },
                        icon: const Icon(Icons.check_circle, size: 22),
                        label: const Text(
                          'CONFIRMAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmSale() async {
    if (_cart.isEmpty) return;

    // Validación final de existencias: ninguna línea puede superar lo que
    // tiene el almacén, aunque el stock haya cambiado desde que se agregó.
    for (final entry in _cart.entries) {
      final prod = _findProduct(entry.key);
      if (prod == null) continue;
      if (ventaExcedeExistencia(producto: prod, cantidad: entry.value)) {
        showErrorMessage(
          context,
          'No hay suficiente existencia de "${prod.nombre}". '
          'Disponible en tu almacén: ${formatearExistencia(prod.existencias)}.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final localStorage = LocalStorage();
    final vendedorId = await localStorage.getVendedorId();
    final cajeroId = await localStorage.getCajeroId();
    final cajaId = await localStorage.getCajaId();
    final almacenId = await localStorage.getAlmacenId();
    final sucursalId = await localStorage.getSucursalId();
    final usuario = await localStorage.getUsuario();

    if (vendedorId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorMessage(
          context,
          'Sesión no válida. Vuelve a iniciar sesión antes de vender.',
        );
      }
      return;
    }

    final List<Map<String, dynamic>> detalles = [];
    _cart.forEach((id, qty) {
      final prod = _findProduct(id);
      if (prod == null) return;
      detalles.add({
        'articulo_id': id,
        'nombre': prod.nombre,
        'unidades': qty,
        'precio_unitario': prod.precio,
        'impuesto_id': prod.impuestoId,
        'porcentaje_impuesto': prod.porcentajeImpuesto,
        'impuestos': prod.impuestos.map((i) => i.toMap()).toList(),
      });
    });

    final totalAmount = _getCartTotalConImpuestos();
    final subtotalSinIva =
        _getCartTotal(); // precio base sin IVA (para el ticket)
    final ventaId = 'VTA-${const Uuid().v4().substring(0, 8).toUpperCase()}';

    double abono = 0;
    List<Map<String, dynamic>>? pagos;

    if (_formaCobroId == 71) {
      final abonoResult = await _showAbonoDialog(context, totalAmount);
      if (abonoResult == null) {
        setState(() => _isLoading = false);
        return;
      }
      abono = abonoResult;
      if (abono > 0) {
        pagos = [
          {'forma_cobro_id': 67, 'importe': abono},
          {'forma_cobro_id': 71, 'importe': totalAmount - abono},
        ];
      }
    }

    final venta = VentaPendiente(
      ventaMovilId: ventaId,
      vendedorId: vendedorId,
      clienteId: widget.cliente.clienteId,
      clienteNombre: widget.cliente.nombreCliente,
      fechaHora: DateTime.now().toIso8601String(),
      estado: 'pendiente',
      total: totalAmount,
      detalles: detalles,
      formaCobroId: _formaCobroId,
      cajaId: cajaId,
      cajeroId: cajeroId,
      almacenId: almacenId,
      sucursalId: sucursalId,
      usuarioCreador: usuario,
      pagos: pagos,
    );

    final syncResult = await _salesRepository.saveAndSyncSale(venta);
    if (mounted) {
      setState(() => _isLoading = false);

      // null = la venta no se guardó (existencia insuficiente en el almacén).
      if (syncResult == null) {
        showErrorMessage(
          context,
          'No se pudo guardar la venta: la existencia disponible de uno o más productos no es suficiente.',
        );
        return;
      }

      final isOnline = syncResult['success'] == true;
      final folio = syncResult['folio'] as String?;
      final folioLocal = syncResult['folio_local'] as String?;
      if (isOnline) {
        showSuccess(context, 'Venta registrada y enviada a Microsip');
      } else {
        showSuccess(context, 'Venta guardada localmente. Lista para sincronizar.');
      }

      // Cargar datos fiscales del emisor para mostrar en el ticket
      String? emisorRfc;
      String? emisorNombre;
      String? sucursalDireccion;
      String? sucursalPoblacion;
      try {
        final db = AppDatabase();
        final emisor = await db.emisorDao.get();
        final sucursal = await db.sucursalDao.get();
        emisorRfc = emisor?.rfc;
        emisorNombre = emisor?.nombreFiscal;
        if (sucursal != null) {
          final direccionParts = <String>[
            if (sucursal.calle.isNotEmpty) sucursal.calle,
            if (sucursal.numExterior.isNotEmpty) '#${sucursal.numExterior}',
            if (sucursal.numInterior.isNotEmpty) 'Int ${sucursal.numInterior}',
            if (sucursal.colonia.isNotEmpty) 'Col. ${sucursal.colonia}',
            if (sucursal.codigoPostal.isNotEmpty) 'CP ${sucursal.codigoPostal}',
          ];
          sucursalDireccion = direccionParts.join(' ');
          sucursalPoblacion = sucursal.poblacion;
        }
      } catch (_) {
        // Si no hay datos fiscales, se omite la seccion en el ticket
      }

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder:
              (_) => VentaExitosaPage(
                clienteNombre: widget.cliente.nombreCliente,
                subtotal: subtotalSinIva,
                ventaId: ventaId,
                folioMicrosip: folio,
                folioLocal: folioLocal,
                isOnline: isOnline,
                detalles: detalles,
                abono: abono,
                emisorRfc: emisorRfc,
                emisorNombre: emisorNombre,
                sucursalDireccion: sucursalDireccion,
                sucursalPoblacion: sucursalPoblacion,
              ),
        ),
      );

      if (mounted) {
        if (result == 'new_sale') {
          setState(() {
            _cart.clear();
            _tabController.animateTo(0);
          });
        } else if (result == 'go_home') {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 0)),
            (route) => false,
          );
        } else if (result == 'go_history') {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 3)),
            (route) => false,
          );
        } else {
          Navigator.pop(context, result);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    final cartItemCount = _getCartDistinctCount();

    final names = widget.cliente.nombreCliente.split(' ');
    final initials =
        (names.length > 1 && names[0].isNotEmpty && names[1].isNotEmpty)
            ? '${names[0][0]}${names[1][0]}'.toUpperCase()
            : widget.cliente.nombreCliente
                .substring(0, min(2, widget.cliente.nombreCliente.length))
                .toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: RutxAppBar(
        title: 'Nueva venta',
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Client Selected Banner
          Container(
            color: AppTheme.textWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cliente.nombreCliente,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Cliente seleccionado',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: AppTheme.textWhite,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentColor,
              labelColor: AppTheme.accentColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: [
                const Tab(text: 'Productos'),
                Tab(text: 'Resumen ($cartItemCount)'),
              ],
            ),
          ),

          // Tab view content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. PRODUCT LIST TAB
                Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppTheme.bgWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),

                    // Products list
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentColor,
                                ),
                              )
                              : filteredProducts.isEmpty
                              ? const Center(
                                child: Text(
                                  'No hay productos disponibles.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              )
                              : Stack(
                                children: [
                                  ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 40,
                                      bottom: 16,
                                    ),
                                    itemCount: filteredProducts.length,
                                    addRepaintBoundaries: true,
                                    addAutomaticKeepAlives: false,
                                    itemBuilder: (context, index) {
                                  final p = filteredProducts[index];
                                  final count = _cart[p.articuloId] ?? 0;
                                  final hasQty = count > 0;

                                  return RepaintBoundary(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            hasQty
                                                ? AppTheme.accentBgLighter
                                                : AppTheme.surfaceCard,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              hasQty
                                                  ? const Color(0xFFFFE0B2)
                                                  : AppTheme.lightGrey,
                                          width: hasQty ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.nombre,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${p.clave} · \$${_precioConImpuesto(p).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: AppTheme.statusGreen,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                StockLabel(
                                                  existencias:
                                                      p.existencias - count,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Product controls
                                          if (unidadesDisponibles(p) <= 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.statusRedBg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Agotado',
                                                style: TextStyle(
                                                  color: AppTheme.statusRed,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                          else if (!hasQty)
                                            GestureDetector(
                                              onTap:
                                                  () =>
                                                      _addToCart(p.articuloId),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentBgLight,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFFFB74D,
                                                    ),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: AppTheme.accentColor,
                                                  size: 20,
                                                ),
                                              ),
                                            )
                                          else
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap:
                                                      () => _removeFromCart(
                                                        p.articuloId,
                                                      ),
                                                  child: Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppTheme
                                                                  .accentColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      color: AppTheme.textWhite,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                      ),
                                                  child: Text(
                                                    '$count',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap:
                                                      () => _addToCart(
                                                        p.articuloId,
                                                      ),
                                                  child: Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppTheme
                                                                  .accentColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      color: AppTheme.textWhite,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                                    _buildAlphabetSidebar(),
                                  if (_isDragging && _currentLetter.isNotEmpty)
                                    _buildLetterIndicatorOverlay(),
                                ],
                              ),
                    ),
                  ],
                ),

                // 2. RESUMEN / SHOPPING CART TAB
                _cart.isEmpty
                    ? const Center(
                      child: Text(
                        'El carrito está vacío.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (listCtx) {
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _cart.length,
                                addRepaintBoundaries: true,
                                addAutomaticKeepAlives: false,
                                itemBuilder: (context, index) {
                                  final keyList = _cart.keys.toList();
                                  final id = keyList[index];
                                  final qty = _cart[id]!;
                                  final prod = _findProduct(id);
                                  if (prod == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return RepaintBoundary(
                                    child: Dismissible(
                                      key: Key('cart_item_$id'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceGrey100,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: AppTheme.textWhite,
                                          size: 26,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        final savedQty = qty;
                                        final savedId = id;
                                        _deleteFromCart(savedId);
                                        _showUndoSnackBar(savedId, savedQty);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.textWhite,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.lightGrey,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    prod.nombre.length > 15
                                                        ? '${prod.nombre.substring(0, 12)}...'
                                                        : prod.nombre,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '\$${_precioConImpuesto(prod).toStringAsFixed(2)} x $qty',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.statusGreen,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  StockLabel(
                                                   existencias:
                                                       prod.existencias - qty,
                                                   showIcon: false,
                                                 ),
                                                ],
                                              ),
                                            ),
                                            // Quantity controls
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap:
                                                      () => _removeFromCart(id),
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.textWhite,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            AppTheme
                                                                .borderLight,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      color:
                                                          AppTheme.surfaceGrey,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  child: Text(
                                                    '$qty',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _addToCart(id),
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.textWhite,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            AppTheme
                                                                .borderLight,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      color:
                                                          AppTheme.surfaceGrey,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '\$${(_precioConImpuesto(prod) * qty).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.statusGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),


                        // Total Estimado Container Box
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.textWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.black05,
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Estimado',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '\$${_getCartTotalConImpuestos().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: AppTheme.statusGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
              ],
            ),
          ),

          // Sticky Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppTheme.textWhite,
            width: double.infinity,
            child:
                _tabController.index == 0
                    ? ElevatedButton(
                      onPressed:
                          _cart.isEmpty
                              ? null
                              : () => _tabController.animateTo(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Revisar pedido ($cartItemCount)',
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed:
                          (_cart.isEmpty || _isLoading) ? null : _confirmSale,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.textWhite,
                                ),
                              )
                              : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Guardando...' : 'Confirmar venta',
                        style: const TextStyle(
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
        ],
      ),
    );
  }
}
