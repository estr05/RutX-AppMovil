import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/shared/widgets/stock_label.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('muestra existencia con enteros', (tester) async {
    await tester.pumpWidget(_wrap(const StockLabel(existencias: 2.0)));

    expect(find.text('Existencia: 2'), findsOneWidget);
  });

  testWidgets('muestra existencia con decimales', (tester) async {
    await tester.pumpWidget(_wrap(const StockLabel(existencias: 2.5)));

    expect(find.text('Existencia: 2.50'), findsOneWidget);
  });

  testWidgets('muestra Agotado cuando la existencia es cero', (tester) async {
    await tester.pumpWidget(_wrap(const StockLabel(existencias: 0.0)));

    expect(find.text('Agotado'), findsOneWidget);
    expect(find.textContaining('Existencia:'), findsNothing);
  });

  testWidgets('oculta el icono cuando showIcon es false', (tester) async {
    await tester.pumpWidget(
      _wrap(const StockLabel(existencias: 3.0, showIcon: false)),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.text('Existencia: 3'), findsOneWidget);
  });
}
