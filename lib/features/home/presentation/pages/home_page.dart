// ignore_for_file: unused_field, unused_local_variable
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../features/catalog/presentation/pages/clientes_page.dart';
import '../../../../features/catalog/presentation/pages/catalogo_page.dart';
import '../../../../features/sales/presentation/pages/ventas_list_page.dart';
// import '../../../../features/credito/presentation/pages/credito_page.dart';
import '../../../../features/summary/presentation/pages/resumen_dia_page.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/summary_metrics_card.dart';
import '../../../../core/storage/local_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../features/home/presentation/widgets/proximo_cliente_card.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  // ---------------------------------------------------------------------------
  // MODALES DEL RESUMEN DEL DÍA
  // ---------------------------------------------------------------------------
  void _showVentasModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomSheet(
            title: 'Desglose de Ventas',
            icon: Icons.attach_money,
            child: FutureBuilder<List<dynamic>>(
              future: _getVentasDelDia(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ventas = snapshot.data!;
                if (ventas.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay ventas registradas.'),
                  );
                }

                double totalContado = 0;
                double totalCredito = 0;
                for (var v in ventas) {
                  if (v['condicion'] == 'Contado') {
                    totalContado += (v['total'] as num).toDouble();
                  } else {
                    totalCredito += (v['total'] as num).toDouble();
                  }
                }
                final total = totalContado + totalCredito;

                return Column(
                  children: [
                    _buildSimpleBarChart(
                      'Contado',
                      totalContado,
                      total,
                      AppTheme.statusGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleBarChart(
                      'Crédito',
                      totalCredito,
                      total,
                      AppTheme.statusOrange,
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: ListView.builder(
                        itemCount: ventas.length,
                        itemBuilder: (context, index) {
                          final v = ventas[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary10,
                              child: Icon(
                                v['condicion'] == 'Contado'
                                    ? Icons.money
                                    : Icons.credit_card,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(v['cliente_nombre'] ?? 'Cliente'),
                            subtitle: Text(v['condicion'] ?? ''),
                            trailing: Text(
                              '\$${(v['total'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showClientesModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomSheet(
            title: 'Clientes Visitados',
            icon: Icons.people_outline,
            child: FutureBuilder<List<dynamic>>(
              future: _getVentasDelDia(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ventas = snapshot.data!;
                if (ventas.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay clientes registrados.'),
                  );
                }

                // Deduplicate clients
                final Map<String, dynamic> clientes = {};
                for (var v in ventas) {
                  clientes[v['cliente_nombre'] ?? 'Desconocido'] = true;
                }
                final lista = clientes.keys.toList();

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlueBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.statusGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Has visitado a ${lista.length} clientes hoy',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.primary10,
                              child: Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(lista[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showPiezasModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomSheet(
            title: 'Piezas Vendidas',
            icon: Icons.inventory_2_outlined,
            child: FutureBuilder<List<dynamic>>(
              future: _getVentasDelDia(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ventas = snapshot.data!;
                if (ventas.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay piezas registradas.'),
                  );
                }

                final Map<String, int> productos = {};
                int totalPiezas = 0;

                for (var v in ventas) {
                  final json = v['detalles_json'];
                  if (json != null) {
                    try {
                      final arr = jsonDecode(json) as List<dynamic>;
                      for (var det in arr) {
                        final nombre = det['nombre'] ?? 'Producto';
                        final qty = (det['unidades'] as num?)?.toInt() ?? 0;
                        productos[nombre] = (productos[nombre] ?? 0) + qty;
                        totalPiezas += qty;
                      }
                    } catch (_) {}
                  }
                }

                final sorted =
                    productos.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.alertWarningBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: AppTheme.statusOrange),
                          const SizedBox(width: 8),
                          Text(
                            'Top Ventas (${totalPiezas} piezas en total)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.statusOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final item = sorted[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Text(
                                  '${item.value} unds',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildSimpleBarChart(
                                '',
                                item.value.toDouble(),
                                sorted.first.value.toDouble(),
                                AppTheme.accentColor,
                                showLabels: false,
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  Future<List<dynamic>> _getVentasDelDia() async {
    final db = AppDatabase();
    final rawDb = await db.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await rawDb.rawQuery(
      '''
      SELECT total, 
             CASE WHEN forma_cobro_id = 67 THEN 'Contado' ELSE 'Crédito' END as condicion, 
             detalles_json, 
             cliente_nombre
      FROM ventas_pendientes
      WHERE fecha_hora LIKE ?
    ''',
      ['$today%'],
    );
  }

  Widget _buildBottomSheet({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(20.0), child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(
    String label,
    double value,
    double max,
    Color color, {
    bool showLabels = true,
  }) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        if (showLabels) const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: showLabels ? 8 : 6,
          ),
        ),
      ],
    );
  }

  // Dashboard Stats
  int _visitedCount = 0;
  int _totalClientes = 0;
  int _totalProductos = 0;
  double _ventasTotalAmount = 0.0;
  int _pendingSalesCount = 0;
  int _piezasVendidas = 0;
  String _vendedorNombre = 'Cargando...';
  Map<String, dynamic>? _nextCliente;
  double _saldoPendiente = 0.0;
  int _clientesAtraso = 0;
  int _inventarioCritico = 0;
  final double _metaDelDia = 10000.0;
  // Dashboard Stats

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadDashboardStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    try {
      final db = AppDatabase();
      await db.initialize();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rawDb = await db.database;

      final resumen = await db.ventaDao.getResumenDelDia(today);
      final totalClientes = await db.clienteDao.count();
      final prodCountResult = await rawDb.rawQuery(
        "SELECT COUNT(*) as total FROM productos WHERE estatus = 'A'",
      );
      final totalProductos = Sqflite.firstIntValue(prodCountResult) ?? 0;

      final nombre = await LocalStorage().getVendedorNombre() ?? 'Usuario';

      final saldoResult = await rawDb.rawQuery(
        "SELECT SUM(saldo) as total_saldo, COUNT(*) as clientes_atraso FROM clientes WHERE saldo > 0",
      );
      final invResult = await rawDb.rawQuery(
        "SELECT COUNT(*) as critico FROM productos WHERE existencias <= 5",
      );

      final nextClienteList = await rawDb.rawQuery(
        '''
        SELECT * FROM clientes
        WHERE cliente_id NOT IN (SELECT cliente_id FROM ventas_pendientes WHERE fecha_hora LIKE ?)
        LIMIT 1
      ''',
        ['$today%'],
      );

      if (mounted) {
        setState(() {
          _vendedorNombre = nombre;
          _totalClientes = totalClientes;
          _totalProductos = totalProductos;
          _visitedCount = resumen['total_ventas'] as int? ?? 0;
          _ventasTotalAmount =
              (resumen['monto_total'] as num? ?? 0.0).toDouble();
          _piezasVendidas = resumen['piezas_vendidas'] as int? ?? 0;
          _pendingSalesCount = resumen['pendientes'] as int? ?? 0;

          if (saldoResult.isNotEmpty) {
            _saldoPendiente =
                (saldoResult.first['total_saldo'] as num?)?.toDouble() ?? 0.0;
            _clientesAtraso =
                (saldoResult.first['clientes_atraso'] as int?) ?? 0;
          }
          if (invResult.isNotEmpty) {
            _inventarioCritico = (invResult.first['critico'] as int?) ?? 0;
          }

          _nextCliente =
              nextClienteList.isNotEmpty ? nextClienteList.first : null;
        });
      }
    } catch (e, st) {
      debugPrint('[Home] Error al cargar dashboard: $e\\n$st');
      if (mounted) {
        showInfo(
          context,
          'Error al cargar indicadores. Desliza para refrescar.',
        );
      }
    }
  }

  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black02,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
    );
  }

  Widget _buildHomeDashboard() {
    final progress =
        _metaDelDia > 0
            ? (_ventasTotalAmount / _metaDelDia).clamp(0.0, 1.0)
            : 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      color: AppTheme.accentColor,
      child: CustomScrollView(
        slivers: [
          const RutxSliverAppBar(title: 'Inicio'),
          SliverToBoxAdapter(
            child: SummaryMetricsCard(
              totalVentas: _ventasTotalAmount,
              clientesVisitados: _visitedCount,
              piezasVendidas: _piezasVendidas,
              onVentasTap: _showVentasModal,
              onClientesTap: _showClientesModal,
              onPiezasTap: _showPiezasModal,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pendingSalesCount > 0) ...[
                    GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 4),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.alertWarningBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.statusAmber),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.categoryOrange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tienes $_pendingSalesCount ${_pendingSalesCount == 1 ? "venta pendiente" : "ventas pendientes"}',
                                    style: const TextStyle(
                                      color: AppTheme.statusOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Se enviarán cuando haya señal',
                                    style: TextStyle(
                                      color: AppTheme.statusOrange,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.categoryOrange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Acciones Rápidas
                  const Text(
                    'ACCIONES RÁPIDAS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          title: 'Clientes',
                          subtitle: '$_totalClientes en ruta',
                          icon: Icons.people_outline,
                          iconColor: AppTheme.avatarBlue,
                          bgColor: AppTheme.infoBlueBg,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickAction(
                          title: 'Catálogos',
                          subtitle: '$_totalProductos productos',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppTheme.categoryOrange,
                          bgColor: AppTheme.alertWarningBg,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CatalogoPage(),
                              ),
                            ).then((_) => _loadDashboardStats());
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta Crédito y Cobranza
                  /*
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreditoPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.textWhite,
                        borderRadius: BorderRadius.circular(16),
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppTheme.alertWarningBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: AppTheme.categoryOrange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Crédito y Cobranza',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Por cobrar: \$${_saldoPendiente.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.statusOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_clientesAtraso > 0) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppTheme.lightGrey),
                            const SizedBox(height: 12),
                            Text(
                              '$_clientesAtraso clientes con saldo pendiente',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  */
                  const Text(
                    'PRÓXIMO CLIENTE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProximoClienteCard(clienteMap: _nextCliente),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(), // 0: Inicio
      ClientesPage(
        key: const ValueKey('clientes'),
        initialFilter: 'Todos',
      ), // 1: Clientes
      ClientesPage(
        key: const ValueKey('vender'),
        initialFilter: 'Pendientes',
        directToSale: true,
      ), // 2: Vender
      const VentasListPage(), // 3: Ventas
      const ResumenDiaPage(), // 4: Más
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _loadDashboardStats();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryColor,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: AppTheme.secondaryColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
            label: 'Vender',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Ventas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
