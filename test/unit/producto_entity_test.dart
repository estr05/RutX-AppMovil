import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/database/entities/producto_entity.dart';

void main() {
  group('Producto.fromMap', () {
    test('crea Producto con datos válidos', () {
      final map = <String, dynamic>{
        'articulo_id': 1,
        'nombre': 'Chocolate Amargo',
        'estatus': 'A',
        'clave': 'CHOC001',
        'precio': 25.50,
        'porcentaje_impuesto': 16,
        'impuesto_id': 622,
        'existencias_gral': 100.0,
        'existencias': 50.0,
        'peso': 0.5,
        'merma': 0.0,
        'permite_merma': 'No',
      };

      final p = Producto.fromMap(map);

      expect(p.articuloId, 1);
      expect(p.nombre, 'Chocolate Amargo');
      expect(p.estatus, 'A');
      expect(p.clave, 'CHOC001');
      expect(p.precio, 25.50);
      expect(p.porcentajeImpuesto, 16);
      expect(p.impuestoId, 622);
      expect(p.existenciasGral, 100.0);
      expect(p.existencias, 50.0);
      expect(p.peso, 0.5);
      expect(p.merma, 0.0);
      expect(p.permiteMerma, 'No');
    });

    test('usa valores por defecto cuando faltan campos opcionales', () {
      final map = <String, dynamic>{
        'articulo_id': 2,
        'nombre': 'Leche',
        'clave': 'LCH001',
        'precio': 18.0,
      };

      final p = Producto.fromMap(map);

      expect(p.articuloId, 2);
      expect(p.estatus, 'A');
      expect(p.porcentajeImpuesto, 16);
      expect(p.impuestoId, 622);
      expect(p.existenciasGral, 0.0);
      expect(p.existencias, 0.0);
      expect(p.peso, 0.0);
      expect(p.merma, 0.0);
      expect(p.permiteMerma, 'No');
    });

    test('lanza StateError cuando clave es null', () {
      final map = <String, dynamic>{
        'articulo_id': 3,
        'nombre': 'Galleta',
        'precio': 10.0,
      };

      expect(
        () => Producto.fromMap(map),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('clave'),
          ),
        ),
      );
    });

    test('lanza StateError cuando precio es null', () {
      final map = <String, dynamic>{
        'articulo_id': 4,
        'nombre': 'Jugo',
        'clave': 'JGO001',
      };

      expect(
        () => Producto.fromMap(map),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('precio'),
          ),
        ),
      );
    });
  });

  group('Producto.toMap', () {
    test('genera mapa correcto con valores especificados', () {
      final p = Producto(
        articuloId: 5,
        nombre: 'Refresco',
        clave: 'RFS001',
        precio: 15.0,
        porcentajeImpuesto: 16,
        impuestoId: 3344,
        existenciasGral: 200.0,
        existencias: 80.0,
        peso: 0.6,
        merma: 0.1,
        permiteMerma: 'Si',
      );

      final map = p.toMap();

      expect(map['articulo_id'], 5);
      expect(map['nombre'], 'Refresco');
      expect(map['estatus'], 'A');
      expect(map['clave'], 'RFS001');
      expect(map['precio'], 15.0);
      expect(map['porcentaje_impuesto'], 16);
      expect(map['impuesto_id'], 3344);
      expect(map['existencias_gral'], 200.0);
      expect(map['existencias'], 80.0);
      expect(map['peso'], 0.6);
      expect(map['merma'], 0.1);
      expect(map['permite_merma'], 'Si');
    });
  });

  group('Producto roundtrip', () {
    test('toMap -> fromMap preserva todos los campos', () {
      final original = Producto(
        articuloId: 10,
        nombre: 'Mantecada',
        clave: 'MTC001',
        precio: 12.50,
        porcentajeImpuesto: 16,
        impuestoId: 622,
        existenciasGral: 30.0,
        existencias: 15.0,
        peso: 0.3,
        merma: 0.0,
        permiteMerma: 'No',
      );

      final map = original.toMap();
      final reconstituted = Producto.fromMap(map);

      expect(reconstituted.articuloId, original.articuloId);
      expect(reconstituted.nombre, original.nombre);
      expect(reconstituted.estatus, original.estatus);
      expect(reconstituted.clave, original.clave);
      expect(reconstituted.precio, original.precio);
      expect(reconstituted.porcentajeImpuesto, original.porcentajeImpuesto);
      expect(reconstituted.impuestoId, original.impuestoId);
      expect(reconstituted.existenciasGral, original.existenciasGral);
      expect(reconstituted.existencias, original.existencias);
      expect(reconstituted.peso, original.peso);
      expect(reconstituted.merma, original.merma);
      expect(reconstituted.permiteMerma, original.permiteMerma);
    });
  });
}
