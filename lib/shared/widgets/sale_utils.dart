import '../../core/database/entities/producto_entity.dart';
import '../../core/database/entities/venta_pendiente_entity.dart';

// =============================================================================
// UTILIDADES COMPARTIDAS PARA VENTAS
// Agrupa logica de calculo de IVA y totales para evitar duplicacion
// entre sale_card, ventas_list_page, resumen_dia_page, venta_detalle_page,
// y venta_exitosa_page.
//
// IMPUESTOS COMPUESTOS: el detalle puede traer una lista 'impuestos'
//   [{impuesto_id, pctje_impuesto}] con TODOS los impuestos del articulo
//   (ej: IVA 16% + IEPS 3%). El factor se calcula como ∏(1 + pctje/100).
//   Si la lista no viene, se usa 'porcentaje_impuesto' (compatibilidad).
// =============================================================================

/// Precio con impuestos COMPUESTOS de un producto (factor ∏(1 + pctje/100)).
/// Usa el precio calculado en el sync; si no vino (datos viejos), lo recalcula.
double precioConImpuestoProducto(Producto p) {
  if (p.precioConImpuesto > 0) return p.precioConImpuesto;
  return p.precio * (1 + p.porcentajeImpuesto / 100);
}

/// Calcula el factor de impuestos (compuesto) de un detalle de venta.
/// - Con lista 'impuestos': ∏(1 + pctje/100)  (ej: 1.16 * 1.03 = 1.1948)
/// - Sin lista: 1 + porcentaje_impuesto / 100
double _factorImpuestos(Map<String, dynamic> d) {
  final impuestos = d['impuestos'] as List?;
  if (impuestos != null && impuestos.isNotEmpty) {
    double factor = 1.0;
    for (final i in impuestos) {
      final m = i as Map;
      final pct = (m['pctje_impuesto'] as num?)?.toDouble() ?? 0.0;
      factor *= 1 + pct / 100;
    }
    return factor;
  }
  final pct = (d['porcentaje_impuesto'] as num?)?.toDouble() ?? 16.0;
  return 1 + pct / 100;
}

/// Calcula el IVA total a partir de los detalles de una venta.
///
/// Cada detalle debe tener:
///   - 'precio_unitario': double (precio sin impuestos)
///   - 'unidades': int (cantidad)
///   - 'impuestos': lista de impuestos compuestos, o 'porcentaje_impuesto'
///
/// Retorna la suma de (precio_unitario * unidades * (factor - 1))
double calcularIVA(List<dynamic> detalles) {
  return detalles.fold<double>(0.0, (sum, d) {
    final precio = (d['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final qty = (d['unidades'] as int?) ?? 0;
    return sum + (precio * qty * (_factorImpuestos(d) - 1));
  });
}

/// Calcula el total con impuestos a partir de los detalles de una venta.
///
/// Retorna la suma de (precio_unitario * unidades * factor_impuestos)
double calcularTotalConIVA(List<dynamic> detalles) {
  double total = 0.0;
  for (final d in detalles) {
    final precio = (d['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final qty = (d['unidades'] as int?) ?? 0;
    total += precio * qty * _factorImpuestos(d);
  }
  return total;
}

/// Calcula el subtotal (sin IVA) a partir de los detalles de una venta.
///
/// Cada detalle debe tener:
///   - 'precio_unitario': double (precio sin IVA)
///   - 'unidades': int (cantidad)
///
/// Retorna la suma de (precio_unitario * unidades)
double calcularSubtotal(List<dynamic> detalles) {
  double total = 0.0;
  for (final d in detalles) {
    final precio = (d['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final qty = (d['unidades'] as int?) ?? 0;
    total += precio * qty;
  }
  return total;
}

/// Calcula el total con IVA para una venta individual [VentaPendiente].
double calcularTotalVentaConIVA(VentaPendiente venta) {
  return calcularTotalConIVA(venta.detalles);
}

/// Calcula el total con IVA para una lista de [VentaPendiente].
double calcularTotalVentasConIVA(List<VentaPendiente> ventas) {
  double total = 0.0;
  for (final v in ventas) {
    total += calcularTotalVentaConIVA(v);
  }
  return total;
}

// =============================================================================
// EXISTENCIAS / STOCK DEL ALMACÉN (el coche del vendedor)
// Las existencias llegan en el sync (`productos[].existencias`) calculadas por
// el sincronizador para el almacén del vendedor (ej. RUTXALMACEN01).
// =============================================================================

/// Unidades enteras que se pueden vender del producto (piso de la existencia).
/// Si la existencia es fraccionaria (ej. 2.5), solo se pueden vender piezas
/// completas (2).
int unidadesDisponibles(Producto p) => p.existencias.floor();

/// Formatea la existencia para la UI: enteros sin decimales (ej. '2') y
/// fracciones con 2 decimales (ej. '2.50').
String formatearExistencia(double existencias) {
  if (existencias == existencias.roundToDouble()) {
    return existencias.toInt().toString();
  }
  return existencias.toStringAsFixed(2);
}

/// ¿Se puede agregar una unidad más al carrito sin exceder la existencia
/// del almacén? Usado al tocar el botón '+' de la venta.
bool puedeAgregarUnidad({required Producto producto, required int enCarrito}) =>
    enCarrito + 1 <= unidadesDisponibles(producto);

/// ¿La cantidad [cantidad] del carrito excede la existencia del almacén?
/// Validación final antes de confirmar la venta.
bool ventaExcedeExistencia({
  required Producto producto,
  required int cantidad,
}) => cantidad > unidadesDisponibles(producto);
