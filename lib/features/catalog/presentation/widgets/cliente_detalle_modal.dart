import 'package:flutter/material.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../core/theme/app_theme.dart';

class ClienteDetalleModal extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onVender;
  final VoidCallback onNoVenta;

  const ClienteDetalleModal({
    Key? key,
    required this.cliente,
    required this.onVender,
    required this.onNoVenta,
  }) : super(key: key);

  static void show(
      BuildContext context, {
        required Cliente cliente,
        required VoidCallback onVender,
        required VoidCallback onNoVenta,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClienteDetalleModal(
        cliente: cliente,
        onVender: onVender,
        onNoVenta: onNoVenta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos si tiene crédito para mostrar sus campos
    final hasCredito = cliente.limiteCredito > 0;
    
    // Obtenemos la dirección concatenando los campos disponibles
    final String direccionCompleta = [
      if (cliente.calle != null && cliente.calle!.isNotEmpty) cliente.calle!,
      if (cliente.codigoPostal != null && cliente.codigoPostal!.isNotEmpty) 'CP: ${cliente.codigoPostal}',
    ].join(', ');

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
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle (pill)
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
            
            // Header: Clave and Type of sale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cliente.clave.isNotEmpty ? cliente.clave : 'SIN CLAVE',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cliente.tipoVenta > 1 ? 'CRÉDITO' : 'CONTADO',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Nombre del cliente
            Text(
              cliente.nombreCliente,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 24),

            // Campos de detalles
            _buildDetailRow('Teléfono', cliente.telefono.isNotEmpty ? cliente.telefono : 'N/A'),
            _buildDetailRow('Dirección', direccionCompleta.isNotEmpty ? direccionCompleta : 'N/A'),
            _buildDetailRow('Población', cliente.poblacion.isNotEmpty ? cliente.poblacion : 'N/A'),
            _buildDetailRow('Colonia', (cliente.colonia != null && cliente.colonia!.isNotEmpty) ? cliente.colonia! : 'N/A'),
            
            // Crédito (condicional)
            if (hasCredito) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppTheme.borderLight),
              ),
              _buildDetailRow('Límite de crédito', '\$${cliente.limiteCredito.toStringAsFixed(2)}', isMoney: true),
              _buildDetailRow('Saldo', '\$${cliente.saldo.toStringAsFixed(2)}', isMoney: true),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cliente.puedeCredito
                      ? AppTheme.statusGreen.withOpacity(0.12)
                      : AppTheme.statusRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      cliente.puedeCredito
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                      color: cliente.puedeCredito
                          ? AppTheme.statusGreen
                          : AppTheme.statusRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente.puedeCredito
                            ? 'Puede vender a crédito (disponible \$${(cliente.limiteCredito - cliente.saldo).toStringAsFixed(2)})'
                            : 'Sin crédito disponible: saldo \$${cliente.saldo.toStringAsFixed(2)} de límite \$${cliente.limiteCredito.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: cliente.puedeCredito
                              ? AppTheme.statusGreen
                              : AppTheme.statusRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: onVender,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusGreen, // El verde significa accionar
                foregroundColor: AppTheme.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.shopping_cart_outlined, size: 22),
              label: const Text(
                'VENDER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onNoVenta,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusRed,
                side: const BorderSide(color: AppTheme.statusRed, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.remove_shopping_cart_outlined, size: 22),
              label: const Text(
                'NO VENTA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMoney = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isMoney ? AppTheme.accentColor : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isMoney ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
