import 'package:flutter/material.dart';

import '../../../../core/network/sync_result.dart';
import '../../../../core/network/connection_state_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../data/sync_repository.dart';

/// Descarga nuevamente en 2 etapas:
///   1. Análisis: consulta el servidor y compara contra lo que ya hay en el
///      equipo (sin modificar nada).
///   2. Descarga incremental: guarda únicamente los datos faltantes, sin
///      duplicar registros ni borrar lo existente.
///
/// Retorna `true` vía Navigator cuando la descarga terminó con éxito.
class ReDescargaSheet extends StatefulWidget {
  const ReDescargaSheet({super.key});

  @override
  State<ReDescargaSheet> createState() => _ReDescargaSheetState();
}

class _ReDescargaSheetState extends State<ReDescargaSheet> {
  final SyncRepository _repository = SyncRepository();

  bool _analizando = true;
  bool _descargando = false;
  bool _completado = false;
  String? _error;
  AnalisisDescarga? _analisis;

  @override
  void initState() {
    super.initState();
    _ejecutarAnalisis();
  }

  Future<void> _ejecutarAnalisis() async {
    if (ConnectionStateService().isOffline) {
      setState(() {
        _error =
            'Sin conexión al servidor. Conéctate a una red e intenta nuevamente.';
        _analizando = false;
      });
      return;
    }
    setState(() {
      _analizando = true;
      _error = null;
    });
    try {
      final analisis = await _repository.analizarDescarga();
      if (!mounted) return;
      setState(() {
        _analisis = analisis;
        _analizando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _analizando = false;
      });
    }
  }

  Future<void> _descargar() async {
    if (ConnectionStateService().isOffline) {
      showWarning(
        context,
        'No hay conexión a internet para descargar datos.',
        title: 'Sin conexión',
      );
      return;
    }
    final analisis = _analisis;
    if (analisis == null || _descargando) return;

    setState(() => _descargando = true);
    final result = await _repository.aplicarDescargaIncremental(analisis);

    if (!mounted) return;

    if (result is SyncSuccess) {
      await LocalStorage().setSyncData(true);
      setState(() {
        _descargando = false;
        _completado = true;
      });
      // Pequeña pausa para que se vea el éxito antes de cerrar.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final failure = result as SyncFailure;
      setState(() => _descargando = false);
      showErrorMessage(context, failure.mensaje);
    }
  }

  Widget _buildFilaComparacion({
    required IconData icon,
    required String titulo,
    required String detalle,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_analizando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.accentColor),
            SizedBox(height: 20),
            Text(
              'Analizando catálogos del servidor...',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'Comparando con lo que ya tienes en el equipo',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppTheme.statusRed),
            const SizedBox(height: 16),
            const Text(
              'No se pudo analizar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _ejecutarAnalisis,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                side: const BorderSide(color: AppTheme.accent50),
              ),
            ),
          ],
        ),
      );
    }

    if (_descargando) {
      final totalNuevos = _analisis?.totalNuevos ?? 0;
      final totalRemovidos = _analisis?.totalRemovidos ?? 0;
      String textoProgreso = 'Actualizando catálogos...';
      if (totalNuevos > 0 && totalRemovidos > 0) {
        textoProgreso =
            'Actualizando catálogo ($totalNuevos nuevos, $totalRemovidos obsoletos)...';
      } else if (totalNuevos > 0) {
        textoProgreso = 'Descargando $totalNuevos elementos faltantes...';
      } else if (totalRemovidos > 0) {
        textoProgreso = 'Depurando $totalRemovidos elementos desasignados...';
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.accentColor),
            const SizedBox(height: 20),
            Text(
              textoProgreso,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus ventas y registros locales se conservan intactos',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_completado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 56, color: AppTheme.statusGreen),
            SizedBox(height: 16),
            Text(
              '¡Descarga completada!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    // ── Resultado del análisis ──────────────────────────────────────────────
    final analisis = _analisis!;
    final estaAlDia = analisis.estaAlDia;

    String mensajeBanner =
        'Estás al día: tu catálogo coincide con el servidor.';
    if (!estaAlDia) {
      if (analisis.totalNuevos > 0 && analisis.totalRemovidos > 0) {
        mensajeBanner =
            'Se encontraron ${analisis.totalNuevos} nuevos y ${analisis.totalRemovidos} a remover.';
      } else if (analisis.totalNuevos > 0) {
        mensajeBanner =
            'Se encontraron ${analisis.totalNuevos} elementos que aún no tienes.';
      } else {
        mensajeBanner =
            'Se encontraron ${analisis.totalRemovidos} elementos en tu equipo que ya no están asignados en el servidor.';
      }
    }

    String detalleProductos =
        '${analisis.productosServidorCount} en servidor · ${analisis.productosLocales} en tu equipo';
    if (analisis.productosNuevosCount > 0) {
      detalleProductos += ' · ${analisis.productosNuevosCount} nuevos';
    }
    if (analisis.productosRemovidosCount > 0) {
      detalleProductos += ' · ${analisis.productosRemovidosCount} a remover';
    }

    String detalleClientes =
        '${analisis.clientesServidorCount} en servidor · ${analisis.clientesLocales} en tu equipo';
    if (analisis.clientesNuevosCount > 0) {
      detalleClientes += ' · ${analisis.clientesNuevosCount} nuevos';
    }
    if (analisis.clientesRemovidosCount > 0) {
      detalleClientes += ' · ${analisis.clientesRemovidosCount} a remover';
    }

    String botonLabel = 'Entendido';
    if (!estaAlDia) {
      if (analisis.totalNuevos > 0 && analisis.totalRemovidos == 0) {
        botonLabel = 'Descargar solo los faltantes (${analisis.totalNuevos})';
      } else if (analisis.totalRemovidos > 0 && analisis.totalNuevos == 0) {
        botonLabel = 'Actualizar y depurar (${analisis.totalRemovidos})';
      } else {
        botonLabel = 'Sincronizar cambios (${analisis.totalCambios})';
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                estaAlDia ? AppTheme.alertSuccessBg : AppTheme.primaryLightBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                estaAlDia ? Icons.task_alt : Icons.compare_arrows,
                color: estaAlDia ? AppTheme.statusGreen : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensajeBanner,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        estaAlDia
                            ? AppTheme.statusGreen
                            : AppTheme.primaryDarkText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildFilaComparacion(
          icon: Icons.inventory_2_outlined,
          titulo: 'Productos',
          detalle: detalleProductos,
        ),
        _buildFilaComparacion(
          icon: Icons.people_outline,
          titulo: 'Clientes',
          detalle: detalleClientes,
        ),
        _buildFilaComparacion(
          icon: Icons.credit_card_outlined,
          titulo: 'Clientes a crédito',
          detalle: '${analisis.creditosServidor} en el catálogo',
          color: AppTheme.statusOrange,
        ),
        _buildFilaComparacion(
          icon: Icons.business_outlined,
          titulo: 'Emisor y sucursal',
          detalle:
              analisis.emisor != null || analisis.sucursal != null
                  ? 'Disponibles en el servidor (se actualizarán)'
                  : 'No incluidos en la respuesta',
          color: AppTheme.categoryTeal,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child:
              estaAlDia
                  ? ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: Text(botonLabel),
                  )
                  : ElevatedButton.icon(
                    onPressed: _descargar,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(botonLabel),
                  ),
        ),
        if (!estaAlDia) ...[
          const SizedBox(height: 8),
          const Text(
            'Tu información actual y tus ventas se conservan intactas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Evita cerrar el sheet (deslizar hacia abajo / botón atrás) mientras la
    // descarga incremental está en curso.
    return PopScope(
      canPop: !_descargando,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.sync, color: AppTheme.accentColor),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Descargar nuevamente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Descarga solo lo que te falte, sin duplicar datos.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                _buildContenido(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
