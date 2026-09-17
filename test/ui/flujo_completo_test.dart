import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ProductRepository productRepo;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    productRepo = ProductRepository(db);
    await productRepo.insert(const Product(
      nombre: 'Leche',
      precioUnitario: 12.5,
      tienda: 'Mercado Central',
    ));
    await productRepo.insert(const Product(
      nombre: 'Arroz',
      precioUnitario: 9.5,
      tienda: 'Mercado Central',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('flujo completo: crear lista, agregar productos, stepper y total en vivo',
      (tester) async {
    await pumpAppWithDb(tester, db);

    await tester.tap(destinoListas());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado Central').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();
    expect(find.text('Mercado Central'), findsOneWidget);

    await tester.tap(find.text('Mercado Central'));
    await tester.pumpAndSettle();
    expect(find.text('La lista está vacía'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar producto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroz'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('\$22,00'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Leche'),
      matching: find.byTooltip('Aumentar cantidad'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('\$34,50'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Arroz'),
      matching: find.byTooltip('Disminuir cantidad'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(find.text('Arroz'), findsNothing);
    expect(find.text('\$25,00'), findsOneWidget);
  });
}