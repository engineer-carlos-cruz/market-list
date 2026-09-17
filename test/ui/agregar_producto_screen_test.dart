import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:market_list/ui/listas/agregar_producto_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ProductRepository productRepo;
  late ShoppingListRepository listRepo;
  late int idLista;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    productRepo = ProductRepository(db);
    listRepo = ShoppingListRepository(db);
    await productRepo.insert(const Product(
      nombre: 'Leche',
      precioUnitario: 12.5,
      tienda: 'Mercado Central',
    ));
    await productRepo.insert(const Product(
      nombre: 'Pan',
      precioUnitario: 5,
      tienda: 'Mercado Central',
    ));
    final deshabilitado = await productRepo.insert(const Product(
      nombre: 'Galletitas',
      precioUnitario: 8,
      tienda: 'Mercado Central',
    ));
    await productRepo.disable(deshabilitado);
    idLista = await listRepo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 13),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> cargarPantalla(WidgetTester tester) =>
      pumpWithDb(tester, db, AgregarProductoScreen(idLista: idLista));

  testWidgets('lista solo los productos activos con tienda y precio',
      (tester) async {
    await cargarPantalla(tester);

    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('Galletitas'), findsNothing);
    expect(find.text('Mercado Central · \$12,50'), findsOneWidget);
    expect(find.text('Mercado Central · \$5,00'), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre', (tester) async {
    await cargarPantalla(tester);

    await tester.enterText(find.byKey(const Key('buscador-productos')), 'pa');
    await tester.pumpAndSettle();

    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('Leche'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('buscador-productos')),
      'zzz',
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay productos que coincidan'), findsOneWidget);
  });

  testWidgets('agregar un producto lo inserta y lo marca como presente',
      (tester) async {
    await cargarPantalla(tester);

    await tester.tap(find.text('Pan'));
    await tester.pumpAndSettle();

    final items = await db.query('shopping_list_items');
    expect(items, hasLength(1));
    expect(items.single['cantidad'], 1);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Pan'));
    expect(tile.enabled, isFalse);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('no se puede tocar dos veces el mismo producto',
      (tester) async {
    await cargarPantalla(tester);

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();

    final items = await db.query('shopping_list_items');
    expect(items, hasLength(1));
  });
}