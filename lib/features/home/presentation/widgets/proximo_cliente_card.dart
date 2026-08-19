import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../features/catalog/presentation/widgets/cliente_detalle_modal.dart';
import '../../../../shared/widgets/feedback_utils.dart';

class ProximoClienteCard extends StatelessWidget {
  final Map<String, dynamic>? clienteMap;

  const ProximoClienteCard({super.key, this.clienteMap});

  void _onCardTapped(BuildContext context) {
    if (clienteMap == null) return;

    // Condición para mostrar el detalle.
    // Por ahora es true == true, pero más adelante será evaluando un valor "PlanMap"
    // que vendrá de una API o permiso para determinar si se despliega el mapa/detalles.
    bool mostrarDetalle = true == true;

    if (mostrarDetalle) {
      try {
        final cliente = Cliente.fromMap(clienteMap!);
        ClienteDetalleModal.show(
          context,
          cliente: cliente,
          onVender: () {
            Navigator.pop(context);
            showInfo(context, "Vender a ${cliente.nombreCliente}");
          },
          onNoVenta: () {
            Navigator.pop(context);
            showInfo(context, "No venta a ${cliente.nombreCliente}");
          },
        );
      } catch (e) {
        showErrorMessage(context, "Error al abrir detalles del cliente");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onCardTapped(context),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  clienteMap != null
                      ? (clienteMap!['nombre_cliente'] as String)
                          .substring(0, 2)
                          .toUpperCase()
                      : 'NA',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clienteMap != null
                        ? clienteMap!['nombre_cliente'] as String
                        : 'Sin clientes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clienteMap != null
                        ? (clienteMap!['calle'] as String?) ?? 'Sin dirección'
                        : 'Todo visitado',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
