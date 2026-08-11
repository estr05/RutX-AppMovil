import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/database/entities/venta_pendiente_entity.dart';
import '../../core/theme/app_theme.dart';

/// Tarjeta que resume una NO VENTA (operación sin ticket).
///
/// A diferencia de [SaleCard], NO muestra folio, total ni artículos: solo
/// motivo, fotografía, comentario y fecha/hora — tal como se registra en
/// la ruta. Los datos viven en el primer elemento de `venta.detalles`
/// (`causa_desc`, `comentario`, `foto_path`).
class NoVentaCard extends StatelessWidget {
  final VentaPendiente venta;

  /// Callback opcional al presionar la tarjeta (navegación al resumen).
  final VoidCallback? onTap;

  const NoVentaCard({
    super.key,
    required this.venta,
    this.onTap,
  });

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight, width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotografía (thumbnail) o placeholder
                _buildFoto(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              venta.clienteNombre,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _NoVentaChip(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Motivo
                      Row(
                        children: [
                          const Icon(Icons.report_problem_outlined,
                              size: 14, color: AppTheme.statusRed),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _causa,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppTheme.statusRed,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_comentario.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _comentario,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Fecha y hora
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(venta.fechaHora),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Estado de sincronización (pendiente / enviada / error)
                      _StatusBadge(style: StatusColor.resolve(venta.estado)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoto() {
    if (_tieneFotoReal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_fotoPath!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.alertErrorBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.photo_camera_outlined,
        color: AppTheme.statusRed,
        size: 24,
      ),
    );
  }
}

class _NoVentaChip extends StatelessWidget {
  const _NoVentaChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusRedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'NO VENTA',
        style: TextStyle(
          color: AppTheme.statusRed,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Badge de estado de sincronización (mismo estilo que [SaleCard]).
class _StatusBadge extends StatelessWidget {
  final StatusBadgeStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
