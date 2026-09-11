import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/repositories/product_repository.dart';
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

void main() {
  late Database db;
  late ProductRepository repo;

  setUp(() async {
    db = await openInMemoryDatabase();
    repo = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert', () {
    test('devuelve un id único y persiste el registro activo', () async {
      final id = await repo.insert(const Product(
        nombre: 'Leche en bolsa x 900 ml',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
      final id2 = await repo.insert(const Product(
        nombre: 'Arroz',
        precioUnitario: 10,
        tienda: 'Tienda B',
      ));

      expect(id, greaterThan(0));
      expect(id2, isNot(id));

      final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows.first['nombre'], 'Leche en bolsa x 900 ml');
      expect(rows.first['precio_unitario'], 12.5);
      expect(rows.first['tienda'], 'Tienda A');
      expect(rows.first['activo'], 1);
    });
  });

  group('update', () {
    test('cambia los datos y conserva el estado de habilitación', () async {
      final id = await repo.insert(const Product(
        nombre: 'Arroz',
        precioUnitario: 10,
        tienda: 'Bodega',
      ));
      await repo.disable(id);

      await repo.update(Product(
        id: id,
        nombre: 'Arroz Largo',
        precioUnitario: 11.5,
        tienda: 'Bodega',
      ));

      final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows.first['nombre'], 'Arroz Largo');
      expect(rows.first['precio_unitario'], 11.5);
      expect(rows.first['tienda'], 'Bodega');
      expect(rows.first['activo'], 0);
    });
  });

  group('disable/enable', () {
    test('deshabilitar y habilitar conserva los datos del producto', () async {
      final id = await repo.insert(const Product(
        nombre: 'Manzana',
        precioUnitario: 3,
        tienda: 'Verdulería',
      ));

      await repo.disable(id);
      var rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
      expect(rows.first['activo'], 0);

      await repo.enable(id);
      rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
      expect(rows.first['activo'], 1);
      expect(rows.first['nombre'], 'Manzana');
      expect(rows.first['precio_unitario'], 3);
      expect(rows.first['tienda'], 'Verdulería');
    });
  });

  group('watchAll', () {
    test('emite el estado inicial con solo productos activos', () async {
      final leche =
          await repo.insert(const Product(nombre: 'leche', precioUnitario: 1, tienda: 'T'));
      await repo.insert(const Product(nombre: 'Zanahoria', precioUnitario: 1, tienda: 'T'));
      await repo.insert(const Product(nombre: 'Arroz', precioUnitario: 1, tienda: 'T'));
      await repo.disable(leche);

      final events = <List<Product>>[];
      final sub = repo.watchAll().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(
        events.first.map((p) => p.nombre),
        ['Arroz', 'Zanahoria'],
      );
    });

    test('se refresca tras cada mutación', () async {
      final events = <List<Product>>[];
      final sub = repo.watchAll().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(events.first, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final manzana = await repo.insert(
        const Product(nombre: 'Manzana', precioUnitario: 3, tienda: 'Verdulería'),
      );
      await _waitForEvents(events, 2);
      expect(events[1].map((p) => p.nombre), ['Manzana']);

      await repo.disable(manzana);
      await _waitForEvents(events, 3);
      expect(events[2], isEmpty);

      await repo.enable(manzana);
      await _waitForEvents(events, 4);
      expect(events[3].map((p) => p.nombre), ['Manzana']);
    });

    test('ordena por nombre sin distinguir mayúsculas y minúsculas', () async {
      await repo.insert(const Product(nombre: 'Naranja', precioUnitario: 1, tienda: 'T'));
      await repo.insert(const Product(nombre: 'agua', precioUnitario: 1, tienda: 'T'));
      await repo.insert(const Product(nombre: 'manzana', precioUnitario: 1, tienda: 'T'));

      final events = <List<Product>>[];
      final sub = repo.watchAll().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvents(events, 1);
      expect(
        events.first.map((p) => p.nombre),
        ['agua', 'manzana', 'Naranja'],
      );
    });
  });
}