import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';

/// Resumen de una NO VENTA (operación sin ticket).
///
/// Muestra únicamente lo que se registró en campo: motivo, fotografía,
/// comentario extra, fecha y hora. No renderiza ticket ni totales.
class NoVentaDetallePage extends StatelessWidget {
  final VentaPendiente venta;

  const NoVentaDetallePage({super.key, required this.venta});

  Map<String, dynamic> get _detalle =>
      venta.detalles.isNotEmpty ? venta.detalles.first : {};

  String get _causa => _detalle['causa_desc'] as String? ?? 'Sin causa';

  String get _comentario => _detalle['comentario'] as String? ?? '';

  String? get _fotoPath => _detalle['foto_path'] as String?;

  bool get _tieneFotoReal {
    final path = _fotoPath;
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Formatea fechaHora (ISO 8601) como `DD/MM/AAAA HH:mm`.
  String _formatDateTime(String fechaHora) {
    try {
      final date = DateTime.parse(fechaHora);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fechaHora;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'Resumen de No Venta',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera: cliente + fecha/hora + estado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venta.clienteNombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusRedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NO VENTA',
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
                  const SizedBox(height: 6),
                  Text(
                    'Cliente ${venta.clienteId}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _EstadoBadge(estado: venta.estado),
                  ),
                  const Divider(height: 24, color: AppTheme.borderLight),
                  _infoRow(
                    Icons.access_time_rounded,
                    'Fecha y hora',
                    _formatDateTime(venta.fechaHora),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Motivo
            const Text(
              'MOTIVO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.alertErrorBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.statusRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.report_problem_outlined, color: AppTheme.statusRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _causa,
                      style: const TextStyle(
                        color: AppTheme.statusRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fotografía
            const Text(
              'FOTOGRAFÍA',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildFoto(),
            const SizedBox(height: 20),

            // Comentario extra
            const Text(
              'COMENTARIO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                _comentario.isEmpty ? 'Sin comentario adicional.' : _comentario,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildFoto() {
    if (_tieneFotoReal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(_fotoPath!),
          width: double.infinity,
          height: 280,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight, width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 56, color: AppTheme.textSecondary),
          SizedBox(height: 8),
          Text(
            'Fotografía no disponible',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Badge de estado de sincronización (pendiente / enviada / error).
class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final style = StatusColor.resolve(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label.toUpperCase(),
        style: TextStyle(
          color: style.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
