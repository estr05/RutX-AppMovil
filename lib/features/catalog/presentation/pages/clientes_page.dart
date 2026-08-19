import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../sales/presentation/pages/nueva_venta_page.dart';
import '../../../sales/presentation/pages/no_venta_page.dart';
import '../widgets/cliente_detalle_modal.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';

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
  String _searchQuery = '';
  late String _selectedFilter; // 'Todos', 'Pendientes', 'Visitados'

  List<Cliente> _clientes = [];
  Map<int, VentaPendiente> _visitasMap = {}; // Maps clienteId -> VentaPendiente
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      await db.initialize();

      final clientesList = await db.clienteDao.getFirst(100);
      clientesList.sort((a, b) => a.clienteId.compareTo(b.clienteId));
      final ventasList = await db.ventaDao.getAll();

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
      print('Error al cargar clientes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Cliente> _getFilteredClientes() {
    return _clientes.where((c) {
      final matchesSearch =
          c.nombreCliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.calle != null &&
              c.calle!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      final isVisited = _visitasMap.containsKey(c.clienteId);
      if (_selectedFilter == 'Pendientes') {
        return !isVisited;
      } else if (_selectedFilter == 'Visitados') {
        return isVisited;
      }
      return true;
    }).toList();
  }

  Color _getAvatarColor(int index) {
    final colors = [
      AppTheme.avatarBlue,
      AppTheme.avatarOrange,
      AppTheme.avatarCyan,
      AppTheme.avatarPurple,
      AppTheme.avatarGreen,
      AppTheme.avatarAmber,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredClientes();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: RutxAppBar(
        title: widget.directToSale ? 'Nueva Venta' : 'Clientes de hoy',
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
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

                // Filters & Filter icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children:
                          ['Todos', 'Pendientes', 'Visitados'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return GestureDetector(
                              onTap:
                                  () =>
                                      setState(() => _selectedFilter = filter),
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

          // Client List
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredList.length,
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                      itemBuilder: (context, index) {
                        final c = filteredList[index];
                        final hasVisited = _visitasMap.containsKey(c.clienteId);
                        final visit = _visitasMap[c.clienteId];

                        // Generar iniciales
                        final names = c.nombreCliente.split(' ');
                        final initials =
                            names.length > 1
                                ? '${names[0][0]}${names[1][0]}'.toUpperCase()
                                : c.nombreCliente.substring(0, 2).toUpperCase();

                        return RepaintBoundary(
                          child: GestureDetector(
                            onTap: () async {
                              if (!hasVisited) {
                                if (widget.directToSale) {
                                  // Ir directo a la venta si estamos en el modo/tab Vender
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
                                  // Mostrar modal si estamos en la lista general de Clientes
                                  ClienteDetalleModal.show(
                                    context,
                                    cliente: c,
                                    onVender: () {
                                      Navigator.pop(context); // Cerrar modal
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
                                      Navigator.pop(context); // Cerrar modal
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
                                  // Avatar
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

                                  // Details
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
                                                overflow: TextOverflow.ellipsis,
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
                                                        ? AppTheme
                                                            .alertSuccessBg
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

                                        // Time & Amount details
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: AppTheme.textSecondary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasVisited
                                                  ? visit!.fechaHora.substring(
                                                    11,
                                                    16,
                                                  )
                                                  : '--:--',
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (hasVisited) ...[
                                              const SizedBox(width: 12),
                                              const Text(
                                                '•',
                                                style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '\$${visit!.total.toStringAsFixed(0)}',
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
