import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/list_line.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/models/shopping_list_item.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:market_list/state/providers/shopping_list_detail_provider.dart';
import 'package:market_list/state/providers/store_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';
import '../../helpers/provider_container.dart';

void main() {
  late Database db;
  late ShoppingListRepository listRepo;
  late ProductRepository productRepo;

  setUp(() async {
    db = await openInMemoryDatabase();
    listRepo = ShoppingListRepository(db);
    productRepo = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertLista() {
    return listRepo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 11),
    ));
  }

  group('shoppingListDetailProvider', () {
    test('emite el detalle de la lista y re-emite tras una mutación', () async {
      final idProducto = await productRepo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Mercado Central',
      ));
      final idLista = await insertLista();
      final idItem = await listRepo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));

      final container = createTestContainer(db);
      final values = <List<ListLine>>[];
      listenTo(container, shoppingListDetailProvider(idLista), values);

      await waitForValues(values, (v) => v.isNotEmpty);
      expect(values.last.map((l) => l.nombre), ['Leche']);
      expect(values.last.single.precioUnitario, 12.5);
      expect(values.last.single.cantidad, 2);

      await listRepo.updateItem(ShoppingListItem(
        id: idItem,
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 5,
      ));
      await waitForValues(
        values,
        (v) => v.last.single.cantidad == 5,
        message: 'Timeout esperando emisión con cantidad actualizada',
      );
      expect(values.last.single.cantidad, 5);
    });
  });

  group('storeProvider', () {
    test('emite las tiendas del catálogo y se refresca con el catálogo', () async {
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

      final container = createTestContainer(db);
      final values = <List<String>>[];
      listenTo(container, storeProvider, values);

      await waitForValues(values, (v) => v.isNotEmpty);
      expect(values.last, ['Feria', 'Mercado Central']);

      await productRepo.insert(const Product(
        nombre: 'Jugo',
        precioUnitario: 8,
        tienda: 'Bodega Sur',
      ));
      await waitForValues(
        values,
        (v) => v.last.contains('Bodega Sur'),
        message: 'Timeout esperando emisión con la tienda nueva',
      );
      expect(values.last, ['Bodega Sur', 'Feria', 'Mercado Central']);
    });
  });
}