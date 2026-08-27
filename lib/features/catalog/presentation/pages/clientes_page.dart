import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../sales/presentation/pages/nueva_venta_page.dart';
import '../../../sales/presentation/pages/no_venta_page.dart';
import '../widgets/cliente_detalle_modal.dart';
import '../../../../shared/widgets/feedback_utils.dart';

/// Lista de clientes del día con paginación por scroll infinito.
///
/// NOTA: Este widget NO contiene un [Scaffold] propio. El [Scaffold] raíz
/// y el [AppBar] son provistos por [HomePage] según el tab activo.
class ClientesPage extends StatefulWidget {
  final String initialFilter;
  final bool directToSale;

  const ClientesPage({
    super.key,
    this.initialFilter = 'Todos',
    this.directToSale = false,
  });

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  // ─── Estado de filtros ───────────────────────────────────────────────────
  String _searchQuery = '';
  late String _selectedFilter; // 'Todos' | 'Pendientes' | 'Visitados'

  // ─── Datos ───────────────────────────────────────────────────────────────
  List<Cliente> _clientes = [];
  Map<int, VentaPendiente> _visitasMap = {}; // clienteId → VentaPendiente
  bool _isLoading = true;

  // ─── Paginación UI (Infinite Scroll) ─────────────────────────────────────
  /// Número de items renderizados actualmente. Se incrementa de 10 en 10
  /// cuando el usuario llega cerca del fondo de la lista.
  int _displayLimit = 30;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // ─── Ciclo de vida ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  /// Listener de scroll: carga el siguiente batch cuando el usuario
  /// está a menos de 200px del fondo. Se ignora si ya está cargando.
  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Comparación barata contra la lista total para no recalcular filtros
      // en cada evento de scroll (pueden ser decenas por segundo).
      if (_displayLimit < _clientes.length) {
        setState(() => _isLoadingMore = true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _displayLimit += 10;
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Carga de datos ──────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      await db.initialize();

      // Sin limite artificial (corregido desde getFirst(100))
      final clientesList = await db.clienteDao.getAll();
      clientesList.sort((a, b) => a.clienteId.compareTo(b.clienteId));

      // Solo visitas de HOY, no contamina días anteriores
      final String hoy = DateTime.now().toIso8601String().substring(0, 10);
      final ventasList = await db.ventaDao.getDelDia(hoy);

      final Map<int, VentaPendiente> visitas = {};
      for (final v in ventasList) {
        visitas[v.clienteId] = v;
      }

      if (mounted) {
        setState(() {
          _clientes = clientesList;
          _visitasMap = visitas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar clientes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Filtrado ────────────────────────────────────────────────────────────

  List<Cliente> _getFilteredClientes() {
    return _clientes.where((c) {
      final matchesSearch =
          c.nombreCliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.calle != null &&
              c.calle!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      final isVisited = _visitasMap.containsKey(c.clienteId);
      if (_selectedFilter == 'Pendientes') return !isVisited;
      if (_selectedFilter == 'Visitados') return isVisited;
      return true;
    }).toList();
  }

  // ─── Helpers visuales ────────────────────────────────────────────────────

  Color _getAvatarColor(int index) {
    const colors = [
      AppTheme.avatarBlue,
      AppTheme.avatarOrange,
      AppTheme.avatarCyan,
      AppTheme.avatarPurple,
      AppTheme.avatarGreen,
      AppTheme.avatarAmber,
    ];
    return colors[index % colors.length];
  }

  /// Extrae iniciales de forma segura evitando [RangeError] por nombres
  /// vacíos, de un solo carácter, o con espacios múltiples.
  String _safeInitials(String nombreCliente) {
    final raw = nombreCliente.trim();
    if (raw.isEmpty) return 'RX';
    final parts = raw.split(RegExp(r'\s+'));
    final first = parts[0];
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (first.length >= 2) return first.substring(0, 2).toUpperCase();
    return first[0].toUpperCase();
  }

  /// Extrae HH:mm de [fechaHora] de forma segura.
  /// Formato esperado: 'YYYY-MM-DD HH:mm:ss' (longitud mínima 16 chars).
  String _safeHora(String? fechaHora) {
    if (fechaHora == null || fechaHora.length < 16) return '--:--';
    return fechaHora.substring(11, 16);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredClientes();

    // Sublista visible calculada UNA vez por build(), evitando
    // take().toList() en cada llamada del itemBuilder (por frame/item).
    final limitList = filteredList.take(_displayLimit).toList();

    return SafeArea(
      child: Column(
        children: [
          // ── Buscador y Filtros ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtros: Todos / Pendientes / Visitados + contador
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: ['Todos', 'Pendientes', 'Visitados'].map((
                        filter,
                      ) {
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap:
                              () => setState(() => _selectedFilter = filter),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryLightBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? AppTheme.textWhite
                                        : AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredList.length}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Lista de Clientes ──────────────────────────────────────────
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    )
                    : filteredList.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay clientes asignados hoy.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      // +1 cuando está cargando el siguiente batch (spinner)
                      itemCount: limitList.length + (_isLoadingMore ? 1 : 0),
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                      itemBuilder: (context, index) {
                        // Spinner de paginación al final de la lista
                        if (index == limitList.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentColor,
                              ),
                            ),
                          );
                        }

                        final c = limitList[index];
                        final hasVisited = _visitasMap.containsKey(
                          c.clienteId,
                        );
                        final visit = _visitasMap[c.clienteId];

                        final initials = _safeInitials(c.nombreCliente);
                        final horaStr =
                            hasVisited
                                ? _safeHora(visit?.fechaHora)
                                : '--:--';

                        return RepaintBoundary(
                          child: GestureDetector(
                            onTap: () async {
                              if (!hasVisited) {
                                if (widget.directToSale) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              NuevaVentaPage(cliente: c),
                                    ),
                                  );
                                  _loadData();
                                } else {
                                  ClienteDetalleModal.show(
                                    context,
                                    cliente: c,
                                    onVender: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  NuevaVentaPage(cliente: c),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    onNoVenta: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  NoVentaPage(cliente: c),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                  );
                                }
                              } else {
                                showInfo(
                                  context,
                                  'Ya fue visitado. ¿Deseas hacer otra venta?',
                                  actionLabel: 'NUEVA VENTA',
                                  onAction: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                NuevaVentaPage(cliente: c),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.textWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.lightGrey),
                              ),
                              child: Row(
                                children: [
                                  // Avatar con iniciales seguras
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getAvatarColor(index),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: AppTheme.textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Detalles del cliente
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.nombreCliente,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    hasVisited
                                                        ? AppTheme.alertSuccessBg
                                                        : AppTheme
                                                            .alertWarningBg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                hasVisited
                                                    ? 'Visitado'
                                                    : 'Pendiente',
                                                style: TextStyle(
                                                  color:
                                                      hasVisited
                                                          ? AppTheme.statusGreen
                                                          : AppTheme
                                                              .categoryOrange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (c.calle != null &&
                                            c.calle!.isNotEmpty)
                                          Text(
                                            'Calle: ${c.calle}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (c.colonia != null &&
                                            c.colonia!.isNotEmpty)
                                          Text(
                                            'Barrio/Col: ${c.colonia}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 6),

                                        // Hora de visita y monto
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: AppTheme.textSecondary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              horaStr,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (hasVisited &&
                                                visit != null) ...[
                                              const SizedBox(width: 12),
                                              const Text(
                                                '•',
                                                style: TextStyle(
                                                  color:
                                                      AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '\$${visit.total.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: AppTheme.statusGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
