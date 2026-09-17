import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/list_line.dart';
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

  Future<int> insertLista() {
    return repo.insert(ShoppingList(
      tienda: 'Mercado Central',
      fecha: DateTime(2026, 9, 11),
    ));
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
      final idProducto2 = await insertProduct('Pan');
      final idLista = await insertLista();

      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 3,
      ));
      final id2 = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto2,
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
      final idLista = await insertLista();

      await expectLater(
        repo.insertItem(ShoppingListItem(
          idLista: idLista,
          idProducto: 9999,
          cantidad: 1,
        )),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rechaza duplicar el mismo producto en la misma lista sin insertar', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();

      await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));

      await expectLater(
        repo.insertItem(ShoppingListItem(
          idLista: idLista,
          idProducto: idProducto,
          cantidad: 3,
        )),
        throwsA(isA<ArgumentError>()),
      );

      final rows = await db.query('shopping_list_items');
      expect(rows, hasLength(1));
      expect(rows.single['cantidad'], 2);
    });

    test('rechaza cantidades no positivas sin insertar', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();

      await expectLater(
        repo.insertItem(ShoppingListItem(
          idLista: idLista,
          idProducto: idProducto,
          cantidad: 0,
        )),
        throwsA(isA<ArgumentError>()),
      );

      final rows = await db.query('shopping_list_items');
      expect(rows, isEmpty);
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
      final idLeche = await insertProduct('Leche');
      final idPan = await insertProduct('Pan');
      final idJugo = await insertProduct('Jugo');
      final lists = await db.query('shopping_lists');
      final idLista = lists.first['id'] as int;

      final items = [
        ShoppingListItem(idLista: idLista, idProducto: idLeche, cantidad: 1),
        ShoppingListItem(idLista: idLista, idProducto: idPan, cantidad: 5),
        ShoppingListItem(idLista: idLista, idProducto: idJugo, cantidad: 2),
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
      final idProducto2 = await insertProduct('Pan');

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
        idProducto: idProducto2,
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

  group('updateItem', () {
    test('actualiza la cantidad conservando el id y las referencias', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 1,
      ));

      await repo.updateItem(ShoppingListItem(
        id: id,
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 4,
      ));

      final rows = await db.query(
        'shopping_list_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.single['cantidad'], 4);
      expect(rows.single['id_lista'], idLista);
      expect(rows.single['id_producto'], idProducto);
    });

    test('rechaza cantidades no positivas y conserva la cantidad anterior', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));

      await expectLater(
        repo.updateItem(ShoppingListItem(
          id: id,
          idLista: idLista,
          idProducto: idProducto,
          cantidad: 0,
        )),
        throwsA(isA<ArgumentError>()),
      );

      final rows = await db.query(
        'shopping_list_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.single['cantidad'], 2);
    });

    test('re-emite los streams de listas e ítems', () async {
      final events = <List<ShoppingListItem>>[];
      final sub = repo.watchAllItems().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, isEmpty);

      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));
      await _waitForCondition(
        () => events.length >= 2 && events.last.isNotEmpty,
        message: 'Timeout esperando emisión con el ítem',
      );

      await repo.updateItem(ShoppingListItem(
        id: id,
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 5,
      ));
      await _waitForCondition(
        () => events.last.map((i) => i.cantidad).toList().length == 1 &&
            events.last.single.cantidad == 5,
        message: 'Timeout esperando emisión con la cantidad actualizada',
      );
      expect(events.last.single.cantidad, 5);
    });
  });

  group('removeItem', () {
    test('elimina el ítem conservando lista y producto', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));

      await repo.removeItem(id);

      final items = await db.query('shopping_list_items');
      expect(items, isEmpty);

      final listas = await db.query('shopping_lists');
      expect(listas, hasLength(1));
      final productos = await db.query('products');
      expect(productos, hasLength(1));
    });

    test('re-emite streams tras el borrado', () async {
      final events = <List<ShoppingListItem>>[];
      final sub = repo.watchAllItems().listen(events.add);
      addTearDown(sub.cancel);
      await _waitForEvents(events, 1);

      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));
      await _waitForCondition(
        () => events.length >= 2 && events.last.isNotEmpty,
        message: 'Timeout esperando emisión con el ítem',
      );

      await repo.removeItem(id);
      await _waitForCondition(
        () => events.length >= 3 && events.last.isEmpty,
        message: 'Timeout esperando emisión sin ítems',
      );
      expect(events.last, isEmpty);
    });
  });

  group('watchListDetail', () {
    test('emite las líneas con producto, ordenadas por nombre', () async {
      final idLeche = await insertProduct('Leche');
      final idArroz = await insertProduct('Arroz');
      final idLista = await insertLista();
      final idLecheItem = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idLeche,
        cantidad: 2,
      ));
      final idArrozItem = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idArroz,
        cantidad: 1,
      ));

      final events = <List<ListLine>>[];
      final sub = repo.watchListDetail(idLista).listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first.map((l) => l.nombre), ['Arroz', 'Leche']);
      expect(events.first[0].precioUnitario, 10);
      expect(events.first[0].id, idArrozItem);
      expect(events.first[1].id, idLecheItem);
      expect(events.first[1].cantidad, 2);
    });

    test('incluye productos deshabilitados con su nombre y precio', () async {
      final idLeche = await insertProduct('Leche');
      final idLista = await insertLista();
      await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idLeche,
        cantidad: 2,
      ));

      await ProductRepository(db).disable(idLeche);

      final events = <List<ListLine>>[];
      final sub = repo.watchListDetail(idLista).listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, hasLength(1));
      expect(events.first.single.nombre, 'Leche');
      expect(events.first.single.activo, isFalse);
    });

    test('se refresca ante mutaciones de ítem de esa lista', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      final id = await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 1,
      ));

      final events = <List<ListLine>>[];
      final sub = repo.watchListDetail(idLista).listen(events.add);
      addTearDown(sub.cancel);
      await _waitForEvents(events, 1);

      await repo.updateItem(ShoppingListItem(
        id: id,
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 3,
      ));
      await _waitForCondition(
        () => events.length >= 2 && events.last.single.cantidad == 3,
        message: 'Timeout esperando emisión con cantidad actualizada',
      );

      await repo.removeItem(id);
      await _waitForCondition(
        () => events.length >= 3 && events.last.isEmpty,
        message: 'Timeout esperando emisión sin ítems',
      );
      expect(events.last, isEmpty);
    });

    test('se refresca ante cambios de producto del catálogo', () async {
      final idProducto = await insertProduct('Leche');
      final idLista = await insertLista();
      await repo.insertItem(ShoppingListItem(
        idLista: idLista,
        idProducto: idProducto,
        cantidad: 2,
      ));

      final events = <List<ListLine>>[];
      final sub = repo.watchListDetail(idLista).listen(events.add);
      addTearDown(sub.cancel);
      await _waitForEvents(events, 1);

      await ProductRepository(db).update(Product(
        id: idProducto,
        nombre: 'Leche',
        precioUnitario: 15,
        tienda: 'Tienda A',
      ));
      await _waitForCondition(
        () => events.length >= 2 && events.last.single.precioUnitario == 15,
        message: 'Timeout esperando emisión con el precio actualizado',
      );
      expect(events.last.single.precioUnitario, 15);
    });
  });

  group('watchStores', () {
    test('emite tiendas distintas ordenadas sin repetidos', () async {
      final prodRepo = ProductRepository(db);
      await prodRepo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 10,
        tienda: 'Mercado Central',
      ));
      await prodRepo.insert(const Product(
        nombre: 'Pan',
        precioUnitario: 5,
        tienda: 'Feria',
      ));
      await prodRepo.insert(const Product(
        nombre: 'Jugo',
        precioUnitario: 8,
        tienda: 'Mercado Central',
      ));

      final events = <List<String>>[];
      final sub = repo.watchStores().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, ['Feria', 'Mercado Central']);
    });

    test('se refresca ante cambios del catálogo', () async {
      final prodRepo = ProductRepository(db);
      await prodRepo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 10,
        tienda: 'Mercado Central',
      ));

      final events = <List<String>>[];
      final sub = repo.watchStores().listen(events.add);
      addTearDown(sub.cancel);
      await _waitForEvents(events, 1);

      await prodRepo.insert(const Product(
        nombre: 'Pan',
        precioUnitario: 5,
        tienda: 'Bodega Sur',
      ));
      await _waitForCondition(
        () => events.length >= 2 && events.last.contains('Bodega Sur'),
        message: 'Timeout esperando emisión con la tienda nueva',
      );
      expect(events.last, ['Bodega Sur', 'Mercado Central']);
    });
  });
}