import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'sale_utils.dart';

/// Etiqueta compacta de existencia (stock del almacén del vendedor) para
/// tarjetas de producto. Cambia de color según el nivel:
/// - Rojo: agotado (0)
/// - Naranja: bajo (1 a 5)
/// - Verde: suficiente (> 5)
class StockLabel extends StatelessWidget {
  final double existencias;
  final bool showIcon;

  const StockLabel({
    super.key,
    required this.existencias,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final agotado = existencias <= 0;
    final color = agotado
        ? AppTheme.statusRed
        : existencias <= 5
            ? AppTheme.statusOrange
            : AppTheme.statusGreen;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(Icons.inventory_2_outlined, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            agotado ? 'Agotado' : 'Existencia: ${formatearExistencia(existencias)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
