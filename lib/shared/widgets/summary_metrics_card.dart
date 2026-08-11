import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SummaryMetricsCard extends StatelessWidget {
  final double totalVentas;
  final int clientesVisitados;
  final int piezasVendidas;
  final VoidCallback? onVentasTap;
  final VoidCallback? onClientesTap;
  final VoidCallback? onPiezasTap;

  const SummaryMetricsCard({
    Key? key,
    required this.totalVentas,
    required this.clientesVisitados,
    required this.piezasVendidas,
    this.onVentasTap,
    this.onClientesTap,
    this.onPiezasTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN DEL DÍA',
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
                child: _buildMetricCard(
                  title: 'Total ventas',
                  value: '\$${totalVentas.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  iconColor: AppTheme.statusGreen,
                  bgColor: AppTheme.statusGreenBg,
                  onTap: onVentasTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Clientes',
                  value: clientesVisitados.toString(),
                  icon: Icons.people_outline,
                  iconColor: AppTheme.avatarBlue,
                  bgColor: AppTheme.infoBlueBg,
                  onTap: onClientesTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Piezas',
                  value: piezasVendidas.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppTheme.statusOrange,
                  bgColor: AppTheme.alertWarningBg,
                  onTap: onPiezasTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
