import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/sync_result.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/sync_repository.dart';
import '../../../../shared/widgets/feedback_utils.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  bool _isSyncing = false;
  bool _hasLocalData = false;
  String _syncStatus = 'En espera';
  String _productsCount = '-- artículos';
  String _clientsCount = '-- clientes';
  String _creditoCount = '-- clientes';
  int _vendedorId = 0;
  String _vendedorNombre = '';

  @override
  void initState() {
    super.initState();
    _checkLocalData();
  }

  Future<void> _checkLocalData() async {
    final ls = LocalStorage();
    _vendedorId = await ls.getVendedorId() ?? 0;
    _vendedorNombre = await ls.getVendedorNombre() ?? 'Vendedor';
    final hasData = await ls.hasSyncData();
    if (mounted) {
      setState(() {
        _hasLocalData = hasData;
        if (hasData) {
          _productsCount = 'Disponibles en caché';
          _clientsCount = 'Disponibles en caché';
          _creditoCount = 'Disponibles en caché';
        }
      });
    }
  }

  Future<void> _forceResync() async {
    final db = AppDatabase();
    await db.initialize();
    await db.limpiarDatosDelDia();
    await LocalStorage().setSyncData(false);
    if (mounted) {
      setState(() {
        _hasLocalData = false;
        _syncStatus = 'En espera';
        _productsCount = '-- artículos';
        _clientsCount = '-- clientes';
        _creditoCount = '-- clientes';
      });
    }
  }

  Widget _buildSyncCard(String title, String subtitle, IconData icon, String status) {
    Color statusColor = AppTheme.textSecondary;
    if (status == 'Descargando...') {
      statusColor = AppTheme.accentColor;
    } else if (status == '¡Completado!') {
      statusColor = AppTheme.statusGreen;
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: status == 'En espera' ? FontWeight.normal : FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Descargando...';
    });

    final result = await SyncRepository().downloadMorningData(_vendedorId);

    if (mounted) {
      if (result is SyncSuccess) {
        setState(() {
          _syncStatus = '¡Completado!';
          _productsCount = '${result.productos} artículos';
          _clientsCount = '${result.clientes} clientes';
          _creditoCount = '${result.credito} clientes';
        });
        await LocalStorage().setSyncData(true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        final error = result as SyncFailure;
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Error';
        });
        showErrorMessage(context, error.mensaje);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Encabezado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'RX',
                          style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('RutX', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Descarga del día', style: TextStyle(color: AppTheme.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Descarga los datos para trabajar sin internet hoy.', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 14)),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black05,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSyncCard('Catálogo de productos', _productsCount, Icons.inventory_2_outlined, _syncStatus),
                        _buildSyncCard('Clientes de la ruta', _clientsCount, Icons.people_outline, _syncStatus),
                        if (_creditoCount != '-- clientes')
                          _buildSyncCard('Clientes a crédito', _creditoCount, Icons.credit_card_outlined, _syncStatus),
                        _buildSyncCard('Lista de precios', 'Vigente hoy', Icons.price_change_outlined, _syncStatus),
                        _buildSyncCard('Ruta asignada', 'Ruta Activa', Icons.map_outlined, _syncStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSyncing && _syncStatus == 'Descargando...')
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(color: AppTheme.accentColor),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _handleSync,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Descargar datos del día', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (_hasLocalData)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        icon: const Icon(Icons.skip_next_outlined),
                        label: const Text('Continuar con datos locales'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                      ),
                  ],
                  const SizedBox(height: 12),
                  if (_hasLocalData)
                    TextButton.icon(
                      onPressed: _forceResync,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Forzar re-sincronización'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
                    ),
                  const SizedBox(height: 16),
                  Text('$_vendedorNombre • Vendedor #$_vendedorId', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
