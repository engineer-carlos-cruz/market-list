import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/models/shopping_list_item.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:market_list/state/providers/shopping_list_item_provider.dart';
import 'package:market_list/state/providers/shopping_list_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';
import '../../helpers/provider_container.dart';

void main() {
  late Database db;
  late ShoppingListRepository repo;

  setUp(() async {
    db = await openInMemoryDatabase();
    repo = ShoppingListRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertProduct(String nombre) {
    return ProductRepository(db).insert(
      Product(nombre: nombre, precioUnitario: 10, tienda: 'Tienda A'),
    );
  }

  test('listas: emite el estado inicial y se refresca tras alta de lista e ítem',
      () async {
    final container = createTestContainer(db);
    final values = <List<ShoppingList>>[];
    listenTo(container, shoppingListProvider, values);

    await waitForValues(values, (v) => v.isNotEmpty);
    expect(values.last, isEmpty);

    final idLista = await repo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 11),
    ));
    await waitForValues(
      values,
      (v) => v.isNotEmpty && v.last.any((l) => l.tienda == 'Mercado Central'),
      message: 'Timeout esperando emisión con la nueva lista',
    );
    expect(values.last.map((l) => l.tienda), ['Mercado Central']);

    final idProducto = await insertProduct('Leche');
    final before = values.length;
    await repo.insertItem(ShoppingListItem(
      idLista: idLista,
      idProducto: idProducto,
      cantidad: 2,
    ));
    await waitForValues(
      values,
      (v) => v.length > before,
      message: 'Timeout esperando re-emisión tras insertar un ítem',
    );
    expect(values.last.map((l) => l.tienda), contains('Mercado Central'));
  });

  test('ítems: emite el estado inicial y se refresca tras alta de ítem',
      () async {
    final container = createTestContainer(db);
    final values = <List<ShoppingListItem>>[];
    listenTo(container, shoppingListItemProvider, values);

    await waitForValues(values, (v) => v.isNotEmpty);
    expect(values.last, isEmpty);

    final idLista = await repo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 11),
    ));
    final idProducto = await insertProduct('Leche');

    await repo.insertItem(ShoppingListItem(
      idLista: idLista,
      idProducto: idProducto,
      cantidad: 2,
    ));
    await waitForValues(
      values,
      (v) => v.any((l) => l.any((i) => i.cantidad == 2)),
      message: 'Timeout esperando emisión con el primer ítem',
    );
    expect(values.last.map((i) => i.cantidad), contains(2));

    await repo.insertItem(ShoppingListItem(
      idLista: idLista,
      idProducto: idProducto,
      cantidad: 4,
    ));
    await waitForValues(
      values,
      (v) => v.last.map((i) => i.cantidad).contains(4),
      message: 'Timeout esperando emisión con el segundo ítem',
    );
    expect(values.last.map((i) => i.cantidad), [2, 4]);
  });
}