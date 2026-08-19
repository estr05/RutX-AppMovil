import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/database/entities/producto_entity.dart';
import 'package:rutx_movil/shared/widgets/sale_utils.dart';

Producto _producto(double existencias) => Producto(
  articuloId: 1,
  nombre: 'Producto de prueba',
  clave: 'PRB001',
  precio: 10.0,
  existencias: existencias,
);

void main() {
  group('unidadesDisponibles', () {
    test('usa el piso de la existencia (solo piezas enteras)', () {
      expect(unidadesDisponibles(_producto(2.0)), 2);
      expect(unidadesDisponibles(_producto(2.5)), 2);
      expect(unidadesDisponibles(_producto(10.99)), 10);
    });

    test('maneja existencia cero o negativa', () {
      expect(unidadesDisponibles(_producto(0.0)), 0);
      expect(unidadesDisponibles(_producto(-1.0)), -1);
    });
  });

  group('formatearExistencia', () {
    test('enteros se muestran sin decimales', () {
      expect(formatearExistencia(2.0), '2');
      expect(formatearExistencia(0.0), '0');
      expect(formatearExistencia(50.0), '50');
    });

    test('fracciones se muestran con 2 decimales', () {
      expect(formatearExistencia(2.5), '2.50');
      expect(formatearExistencia(1.25), '1.25');
    });
  });

  group('puedeAgregarUnidad', () {
    test('permite agregar hasta alcanzar la existencia', () {
      final p = _producto(2.0);
      expect(puedeAgregarUnidad(producto: p, enCarrito: 0), isTrue);
      expect(puedeAgregarUnidad(producto: p, enCarrito: 1), isTrue);
      expect(puedeAgregarUnidad(producto: p, enCarrito: 2), isFalse);
    });

    test('no permite agregar cuando no hay existencia', () {
      final p = _producto(0.0);
      expect(puedeAgregarUnidad(producto: p, enCarrito: 0), isFalse);
    });

    test('no permite agregar con existencia fraccionaria menor a 1', () {
      final p = _producto(0.5);
      expect(puedeAgregarUnidad(producto: p, enCarrito: 0), isFalse);
    });
  });

  group('ventaExcedeExistencia', () {
    test('detecta cuando la cantidad supera la existencia', () {
      final p = _producto(2.0);
      expect(ventaExcedeExistencia(producto: p, cantidad: 2), isFalse);
      expect(ventaExcedeExistencia(producto: p, cantidad: 3), isTrue);
    });

    test('detecta venta con existencia cero', () {
      final p = _producto(0.0);
      expect(ventaExcedeExistencia(producto: p, cantidad: 1), isTrue);
    });
  });
}
