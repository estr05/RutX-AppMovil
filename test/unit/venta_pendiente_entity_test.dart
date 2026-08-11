import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/database/entities/venta_pendiente_entity.dart';

Map<String, dynamic> _fullMap() => {
  'venta_movil_id': 'VTA-ABC123',
  'vendedor_id': 695,
  'cliente_id': 100,
  'cliente_nombre': 'Juan Pérez',
  'fecha_hora': '2026-07-28T10:30:00.000',
  'estado': 'pendiente',
  'total': 150.0,
  'detalles_json': '[{"articulo_id":1,"unidades":2,"precio_unitario":75.0,"impuesto_id":622}]',
  'forma_cobro_id': 67,
  'caja_id': null,
  'docto_pv_id': null,
  'folio': null,
  'pagos_json': null,
};

void main() {
  group('VentaPendiente.fromMap', () {
    test('crea venta desde mapa completo', () {
      final v = VentaPendiente.fromMap(_fullMap());

      expect(v.ventaMovilId, 'VTA-ABC123');
      expect(v.vendedorId, 695);
      expect(v.clienteId, 100);
      expect(v.clienteNombre, 'Juan Pérez');
      expect(v.estado, 'pendiente');
      expect(v.total, 150.0);
      expect(v.detalles.length, 1);
      expect(v.detalles.first['articulo_id'], 1);
      expect(v.formaCobroId, 67);
      expect(v.cajaId, isNull);
      expect(v.doctoPvId, isNull);
      expect(v.folio, isNull);
      expect(v.pagos, isEmpty);
    });

    test('usa valores por defecto cuando faltan campos', () {
      final map = <String, dynamic>{
        'venta_movil_id': 'VTA-XYZ',
        'vendedor_id': 1,
        'cliente_id': 1,
        'cliente_nombre': 'Test',
        'fecha_hora': '2026-01-01T00:00:00',
      };

      final v = VentaPendiente.fromMap(map);

      expect(v.estado, 'pendiente');
      expect(v.total, 0.0);
      expect(v.detalles, isEmpty);
      expect(v.formaCobroId, 67);
    });

    test('parsea detalles_json vacío como lista vacía', () {
      final map = _fullMap();
      map['detalles_json'] = '[]';
      final v = VentaPendiente.fromMap(map);

      expect(v.detalles, isEmpty);
    });

    test('parsea detalles_json null como lista vacía', () {
      final map = _fullMap();
      map['detalles_json'] = null;
      final v = VentaPendiente.fromMap(map);

      expect(v.detalles, isEmpty);
    });

    test('parsea pagos_json cuando no es null', () {
      final map = _fullMap();
      map['pagos_json'] = '[{"forma_cobro_id":67,"importe":100.0}]';
      final v = VentaPendiente.fromMap(map);

      expect(v.pagos, isNotNull);
      expect(v.pagos!.length, 1);
      expect(v.pagos!.first['forma_cobro_id'], 67);
    });
  });

  group('VentaPendiente.toMap', () {
    test('genera mapa que incluye detalles_json y pagos_json', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-TEST',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
        total: 100.0,
        detalles: [{'articulo_id': 1, 'unidades': 1, 'precio_unitario': 100.0}],
        pagos: [{'forma_cobro_id': 67, 'importe': 100.0}],
      );

      final map = v.toMap();

      expect(map['venta_movil_id'], 'VTA-TEST');
      expect(map['detalles_json'], isA<String>());
      expect(map['pagos_json'], isA<String>());
      expect(map['pagos_json'], isNotNull);
    });

    test('pagos_json es null cuando no hay pagos', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-TEST2',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
      );

      final map = v.toMap();

      expect(map['pagos_json'], isNull);
    });

    test('pagos es null por defecto en constructor', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-TEST2',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
      );

      expect(v.pagos, isNull);
    });
  });

  group('VentaPendiente.toPvJson', () {
    test('incluye pagos cuando existen', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-PV',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
        formaCobroId: 71,
        detalles: [{'articulo_id': 1, 'unidades': 2, 'precio_unitario': 50.0, 'impuesto_id': 622}],
        pagos: [{'forma_cobro_id': 67, 'importe': 50.0}, {'forma_cobro_id': 71, 'importe': 50.0}],
      );

      final json = v.toPvJson();

      expect(json['pagos'], isNotNull);
      expect((json['pagos'] as List).length, 2);
      expect(json['detalles'], isA<List>());
    });

    test('no incluye pagos cuando es null', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-PV2',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
        detalles: [{'articulo_id': 1, 'unidades': 1, 'precio_unitario': 50.0, 'impuesto_id': 622}],
      );

      final json = v.toPvJson();

      expect(json.containsKey('pagos'), false);
    });
  });

  group('VentaPendiente.toNoVentaJson', () {
    test('retorna detalle vacío cuando no hay detalles', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-NV',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Test',
        fechaHora: '2026-01-01T00:00:00',
      );

      final json = v.toNoVentaJson();

      expect(json['causa_id'], 0);
      expect(json['causa_desc'], 'Sin causa');
    });
  });

  group('VentaPendiente.copyWith', () {
    test('actualiza solo los campos especificados', () {
      final v = VentaPendiente(
        ventaMovilId: 'VTA-CW',
        vendedorId: 1,
        clienteId: 1,
        clienteNombre: 'Original',
        fechaHora: '2026-01-01T00:00:00',
        estado: 'pendiente',
      );

      final updated = v.copyWith(estado: 'enviada', folio: 'V0000001');

      expect(updated.estado, 'enviada');
      expect(updated.folio, 'V0000001');
      expect(updated.clienteNombre, 'Original');
    });
  });

  group('VentaPendiente roundtrip', () {
    test('toMap -> fromMap preserva datos', () {
      final original = VentaPendiente(
        ventaMovilId: 'VTA-RT',
        vendedorId: 695,
        clienteId: 100,
        clienteNombre: 'Roundtrip Test',
        fechaHora: '2026-07-28T12:00:00.000',
        total: 250.0,
        detalles: [
          {'articulo_id': 1, 'unidades': 5, 'precio_unitario': 50.0, 'impuesto_id': 622},
        ],
        formaCobroId: 67,
      );

      final map = original.toMap();
      final reconstituted = VentaPendiente.fromMap(map);

      expect(reconstituted.ventaMovilId, original.ventaMovilId);
      expect(reconstituted.vendedorId, original.vendedorId);
      expect(reconstituted.clienteId, original.clienteId);
      expect(reconstituted.clienteNombre, original.clienteNombre);
      expect(reconstituted.total, original.total);
      expect(reconstituted.formaCobroId, original.formaCobroId);
      expect(reconstituted.detalles.length, original.detalles.length);
    });
  });
}
