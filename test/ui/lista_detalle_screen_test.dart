import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/models/shopping_list_item.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:market_list/ui/listas/lista_detalle_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ProductRepository productRepo;
  late ShoppingListRepository listRepo;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    productRepo = ProductRepository(db);
    listRepo = ShoppingListRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertarListaConLeche(int cantidad) async {
    final idLeche = await productRepo.insert(const Product(
      nombre: 'Leche',
      precioUnitario: 12.5,
      tienda: 'Mercado Central',
    ));
    final idLista = await listRepo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 13),
    ));
    await listRepo.insertItem(ShoppingListItem(
      idLista: idLista,
      idProducto: idLeche,
      cantidad: cantidad,
    ));
    return idLista;
  }

  testWidgets('muestra tienda, fecha, línea con precio y total', (tester) async {
    final idLista = await insertarListaConLeche(2);

    await pumpWithDb(tester, db, ListaDetalleScreen(idLista: idLista));

    expect(find.text('Mercado Central'), findsOneWidget);
    expect(
      find.text(DateFormat('d MMM yyyy', 'es_ES').format(DateTime(2026, 9, 13))),
      findsOneWidget,
    );
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('\$12,50'), findsOneWidget);
    expect(find.text('\$25,00'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('la lista vacía muestra el estado vacío y total en cero',
      (tester) async {
    final idLista = await listRepo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 13),
    ));

    await pumpWithDb(tester, db, ListaDetalleScreen(idLista: idLista));

    expect(find.text('La lista está vacía'), findsOneWidget);
    expect(find.text('\$0,00'), findsOneWidget);
  });

  testWidgets('el stepper incrementa y decrementa la cantidad y el total',
      (tester) async {
    final idLista = await insertarListaConLeche(2);

    await pumpWithDb(tester, db, ListaDetalleScreen(idLista: idLista));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$25,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Aumentar cantidad'));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('\$37,50'), findsOneWidget);

    await tester.tap(find.byTooltip('Disminuir cantidad'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$25,00'), findsOneWidget);

    final rows = await db.query('shopping_list_items');
    expect(rows.single['cantidad'], 2);
  });

  testWidgets('decrementar en 1 abre confirmación; cancelar conserva y confirmar elimina',
      (tester) async {
    final idLista = await insertarListaConLeche(1);

    await pumpWithDb(tester, db, ListaDetalleScreen(idLista: idLista));
    expect(find.text('Leche'), findsOneWidget);

    await tester.tap(find.byTooltip('Disminuir cantidad'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('se quitará de la lista'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('\$12,50'), findsWidgets);

    await tester.tap(find.byTooltip('Disminuir cantidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(find.text('Leche'), findsNothing);
    expect(find.text('La lista está vacía'), findsOneWidget);
    expect(find.text('\$0,00'), findsOneWidget);
  });

  testWidgets('un producto deshabilitado sigue visible con nombre y precio',
      (tester) async {
    final idLista = await insertarListaConLeche(2);
    final productos = await db.query('products');
    await productRepo.disable(productos.single['id'] as int);

    await pumpWithDb(tester, db, ListaDetalleScreen(idLista: idLista));

    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('\$12,50'), findsOneWidget);
    expect(find.text('\$25,00'), findsOneWidget);
  });
}