import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutx_movil/core/helpers/jornada_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JornadaHelper.jornadaCerradaHoy', () {
    test('retorna false cuando no hay cierre registrado', () async {
      final result = await JornadaHelper.jornadaCerradaHoy();
      expect(result, isFalse);
    });

    test('retorna true cuando el cierre fue registrado hoy', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dia_cerrado', DateTime.now().toIso8601String());

      final result = await JornadaHelper.jornadaCerradaHoy();
      expect(result, isTrue);
    });

    test('retorna false cuando el cierre fue registrado ayer', () async {
      final prefs = await SharedPreferences.getInstance();
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      await prefs.setString('dia_cerrado', ayer.toIso8601String());

      final result = await JornadaHelper.jornadaCerradaHoy();
      expect(result, isFalse);
    });

    test('retorna false cuando la cadena es invalida', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dia_cerrado', 'fecha_invalida');

      final result = await JornadaHelper.jornadaCerradaHoy();
      expect(result, isFalse);
    });

    test('retorna false cuando la cadena está vacía', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dia_cerrado', '');

      final result = await JornadaHelper.jornadaCerradaHoy();
      expect(result, isFalse);
    });
  });

  group('JornadaHelper.guardarCierreJornada', () {
    test('guarda la fecha correctamente', () async {
      await JornadaHelper.guardarCierreJornada(DateTime(2026, 8, 25));

      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString('dia_cerrado');
      expect(guardado, contains('2026-08-25'));
    });
  });

  group('JornadaHelper.limpiarCierreJornada', () {
    test('limpia el cierre registrado', () async {
      await JornadaHelper.guardarCierreJornada(DateTime.now());

      final antes = await JornadaHelper.jornadaCerradaHoy();
      expect(antes, isTrue);

      await JornadaHelper.limpiarCierreJornada();

      final despues = await JornadaHelper.jornadaCerradaHoy();
      expect(despues, isFalse);
    });
  });
}
