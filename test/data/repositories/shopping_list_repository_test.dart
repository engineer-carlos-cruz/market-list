import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/models/shopping_list_item.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';

Future<void> _waitForEvents<T>(
  List<T> events,
  int count, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (events.length < count) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timeout esperando $count eventos; recibidos ${events.length}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Future<void> _waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  String? message,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(message ?? 'Timeout esperando que se cumpla la condición');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

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

  group('insert', () {
    test('devuelve un id único y persiste la lista', () async {
      final id = await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 10, 15, 30),
      ));
      final id2 = await repo.insert(ShoppingList(
        tienda: 'Bodega Sur',
        fecha: DateTime(2026, 9, 11, 9, 0),
      ));

      expect(id, greaterThan(0));
      expect(id2, isNot(id));

      final rows = await db.query('shopping_lists', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows.first['tienda'], 'Mercado Central');
      expect(rows.first['fecha'], DateTime(2026, 9, 10, 15, 30).toIso8601String());
    });
  });

  group('insertItem', () {
    test('persiste el ítem con FK válido y cantidad positiva, devolviendo su id', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 11),
      ));

      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 3,
      ));
      final id2 = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 1,
      ));

      expect(id, greaterThan(0));
      expect(id2, isNot(id));

      final rows =
          await db.query('shopping_list_items', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows.first['id_lista'], idLista);
      expect(rows.first['id_producto'], idProducto);
      expect(rows.first['cantidad'], 3);
    });

    test('rechaza un ítem con FK inexistente', () async {
      final idLista = await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 11),
      ));

      await expectLater(
        repo.insertItem(ShoppingListItem(
          idLista: idLista,
          idProducto: 9999,
          cantidad: 1,
        )),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('watchAll', () {
    test('emite el estado inicial ordenado por fecha DESC', () async {
      await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 9),
      ));
      await repo.insert(ShoppingList(
        tienda: 'Bodega Sur',
        fecha: DateTime(2026, 9, 11),
      ));
      await repo.insert(ShoppingList(
        tienda: 'Feria',
        fecha: DateTime(2026, 9, 10),
      ));

      final events = <List<ShoppingList>>[];
      final sub = repo.watchAll().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first.map((l) => l.tienda), ['Bodega Sur', 'Feria', 'Mercado Central']);
    });

    test('se refresca tras cada mutación de lista o de ítem', () async {
      final events = <List<ShoppingList>>[];
      final sub = repo.watchAll().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final idLista = await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 11),
      ));
      await _waitForEvents(events, 2);
      expect(events[1].map((l) => l.tienda), ['Mercado Central']);

      final idProducto = await insertProduct('Leche');
      await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));
      await _waitForEvents(events, 3);
      expect(events[2].map((l) => l.tienda), ['Mercado Central']);
    });
  });

  group('watchAllItems', () {
    test('emite el estado inicial con todos los ítems ordenados por id', () async {
      await repo.insert(ShoppingList(tienda: 'Mercado', fecha: DateTime(2026, 9, 11)));
      final idProducto = await insertProduct('Leche');
      final lists = await db.query('shopping_lists');
      final idLista = lists.first['id'] as int;

      final items = [
        ShoppingListItem(idLista: idLista, idProducto: idProducto, cantidad: 1),
        ShoppingListItem(idLista: idLista, idProducto: idProducto, cantidad: 5),
        ShoppingListItem(idLista: idLista, idProducto: idProducto, cantidad: 2),
      ];
      for (final item in items) {
        await repo.insertItem(item);
      }

      final events = <List<ShoppingListItem>>[];
      final sub = repo.watchAllItems().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first.map((i) => i.cantidad), [1, 5, 2]);
    });

    test('se refresca tras cada alta de ítem', () async {
      final events = <List<ShoppingListItem>>[];
      final sub = repo.watchAllItems().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 10));

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
      await _waitForCondition(
        () => events.length >= 2 && events.last.isNotEmpty,
        message: 'Timeout esperando emisión con el primer ítem',
      );
      expect(events.last.map((i) => i.cantidad), [2]);

      await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 4,
      ));
      await _waitForCondition(
        () => events.length >= 3 &&
            events.last.map((i) => i.cantidad).toList().length == 2,
        message: 'Timeout esperando emisión con dos ítems',
      );
      expect(events.last.map((i) => i.cantidad), [2, 4]);
    });
  });
}