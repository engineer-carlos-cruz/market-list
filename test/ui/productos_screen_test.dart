import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/models/shopping_list_item.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:market_list/ui/productos/productos_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ProductRepository repo;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    repo = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Listado', () {
    testWidgets('muestra nombre, precio formateado y tienda de los activos',
        (tester) async {
      await repo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
      await repo.insert(const Product(
        nombre: 'Arroz',
        precioUnitario: 10,
        tienda: 'Tienda B',
      ));

      await pumpWithDb(tester, db, const ProductosScreen());

      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('\$10,00'), findsOneWidget);
      expect(find.text('Tienda B'), findsOneWidget);
      expect(find.text('Leche'), findsOneWidget);
      expect(find.text('\$12,50'), findsOneWidget);
      expect(find.text('Tienda A'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío cuando no hay productos',
        (tester) async {
      await pumpWithDb(tester, db, const ProductosScreen());

      expect(find.text('Aún no hay productos'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('el FAB conduce al formulario de alta', (tester) async {
      await pumpAppWithDb(tester, db);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo producto'), findsOneWidget);
    });

    testWidgets('se refresca solo tras una mutación externa', (tester) async {
      await pumpWithDb(tester, db, const ProductosScreen());
      expect(find.text('Aún no hay productos'), findsOneWidget);

      await repo.insert(const Product(
        nombre: 'Manzana',
        precioUnitario: 3,
        tienda: 'Verdulería',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Manzana'), findsOneWidget);
      expect(find.text('\$3,00'), findsOneWidget);
    });
  });

  group('Borrado', () {
    Future<int> insertarLeche() async {
      return repo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
    }

    testWidgets('deslizar abre el diálogo de confirmación y cancelar "deja la fila intacta"',
        (tester) async {
      await insertarLeche();
      await pumpWithDb(tester, db, const ProductosScreen());

      await tester.drag(find.text('Leche'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('desaparecerá de la lista de productos'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Leche'), findsOneWidget);
      expect(find.text('\$12,50'), findsOneWidget);
    });

    testWidgets('confirmar borra el producto y conserva la lista que lo referencia',
        (tester) async {
      final idLeche = await insertarLeche();
      final listRepo = ShoppingListRepository(db);
      final idLista = await listRepo.insert(ShoppingList(
        tienda: 'Tienda A',
        fecha: DateTime(2026, 9, 13),
      ));
      await listRepo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idLeche,
        cantidad: 2,
      ));

      await pumpWithDb(tester, db, const ProductosScreen());
      expect(find.text('Leche'), findsOneWidget);

      await tester.drag(find.text('Leche'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Leche'), findsNothing);

      final productos = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [idLeche],
      );
      expect(productos.single['activo'], 0);

      final items = await db.query('shopping_list_items');
      expect(items.single['id_producto'], idLeche);
      expect(items.single['cantidad'], 2);
    });
  });
}