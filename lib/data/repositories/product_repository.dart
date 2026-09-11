import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._db);

  final Database _db;

  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  Future<int> insert(Product product) async {
    final id = await _db
        .insert('products', product.toMap(withId: false));
    _changes.add(null);
    return id;
  }

  Future<void> update(Product product) async {
    await _db.update(
      'products',
      {
        'nombre': product.nombre,
        'precio_unitario': product.precioUnitario,
        'tienda': product.tienda,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
    _changes.add(null);
  }

  Future<void> disable(int id) => _setActive(id, 0);

  Future<void> enable(int id) => _setActive(id, 1);

  Future<void> _setActive(int id, int activo) async {
    await _db.update(
      'products',
      {'activo': activo},
      where: 'id = ?',
      whereArgs: [id],
    );
    _changes.add(null);
  }

  Stream<List<Product>> watchAll() {
    return () async* {
      yield await _queryActive();
      yield* _changes.stream.asyncMap((_) => _queryActive());
    }();
  }

  Future<List<Product>> _queryActive() async {
    final rows = await _db.query(
      'products',
      where: 'activo = 1',
      orderBy: 'nombre COLLATE NOCASE',
    );
    return rows.map(Product.fromMap).toList();
  }
}