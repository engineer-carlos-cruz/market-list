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
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> irANuevaLista(WidgetTester tester) async {
    await pumpAppWithDb(tester, db);
    await tester.tap(destinoListas());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  testWidgets('ofrece las tiendas del catálogo como selección y crea la lista',
      (tester) async {
    await productRepo.insert(const Product(
      nombre: 'Leche',
      precioUnitario: 10,
      tienda: 'Mercado Central',
    ));
    await productRepo.insert(const Product(
      nombre: 'Pan',
      precioUnitario: 5,
      tienda: 'Feria',
    ));

    await irANuevaLista(tester);

    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado Central').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();

    final listas = await db.query('shopping_lists');
    expect(listas, hasLength(1));
    expect(listas.single['tienda'], 'Mercado Central');
    expect(find.text('Mercado Central'), findsOneWidget);
  });

  testWidgets('permite crear una lista con una tienda nueva', (tester) async {
    await irANuevaLista(tester);

    await tester.enterText(find.byType(TextField), 'Feria Nueva');
    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();

    final listas = await db.query('shopping_lists');
    expect(listas, hasLength(1));
    expect(listas.single['tienda'], 'Feria Nueva');
    expect(find.text('Feria Nueva'), findsOneWidget);
  });

  testWidgets('muestra la guía cuando el catálogo no tiene tiendas',
      (tester) async {
    await irANuevaLista(tester);

    expect(
      find.textContaining('Aún no hay tiendas en el catálogo'),
      findsOneWidget,
    );
  });

  testWidgets('no crea la lista sin tienda y muestra error que se limpia',
      (tester) async {
    await irANuevaLista(tester);

    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();

    expect(find.text('La tienda es obligatoria'), findsOneWidget);
    expect(await db.query('shopping_lists'), isEmpty);

    await tester.enterText(find.byType(TextField), 'Tienda Nueva');
    await tester.pumpAndSettle();

    expect(find.text('La tienda es obligatoria'), findsNothing);
  });
}