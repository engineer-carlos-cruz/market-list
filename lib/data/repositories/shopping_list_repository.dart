import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../database/change_bus.dart';
import '../models/list_line.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';

class ShoppingListRepository {
  ShoppingListRepository(this._db) : _changes = DatabaseChanges.forDb(_db);

  final Database _db;

  final StreamController<void> _changes;

  Future<int> insert(ShoppingList list) async {
    final id = await _db
        .insert('shopping_lists', list.toMap(withId: false));
    _changes.add(null);
    return id;
  }

  Future<int> insertItem(ShoppingListItem item) async {
    if (item.cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor a cero');
    }
    final dupes = await _db.rawQuery(
      'SELECT count(*) AS n FROM shopping_list_items '
      'WHERE id_lista = ? AND id_producto = ?',
      [item.idLista, item.idProducto],
    );
    final count = Sqflite.firstIntValue(dupes) ?? 0;
    if (count > 0) {
      throw ArgumentError('El producto ya está en la lista');
    }
    final id = await _db
        .insert('shopping_list_items', item.toMap(withId: false));
    _changes.add(null);
    return id;
  }

  Future<void> updateItem(ShoppingListItem item) async {
    if (item.cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor a cero');
    }
    await _db.update(
      'shopping_list_items',
      {'cantidad': item.cantidad},
      where: 'id = ?',
      whereArgs: [item.id],
    );
    _changes.add(null);
  }

  Future<void> removeItem(int id) async {
    await _db.delete(
      'shopping_list_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    _changes.add(null);
  }

  Stream<List<ShoppingList>> watchAll() {
    return () async* {
      yield await _queryLists();
      yield* _changes.stream.asyncMap((_) => _queryLists());
    }();
  }

  Stream<List<ShoppingListItem>> watchAllItems() {
    return () async* {
      yield await _queryItems();
      yield* _changes.stream.asyncMap((_) => _queryItems());
    }();
  }

  Stream<List<ListLine>> watchListDetail(int idLista) {
    return () async* {
      yield await _queryDetail(idLista);
      yield* _changes.stream.asyncMap((_) => _queryDetail(idLista));
    }();
  }

  Stream<List<String>> watchStores() {
    return () async* {
      yield await _queryStores();
      yield* _changes.stream.asyncMap((_) => _queryStores());
    }();
  }

  Future<List<ShoppingList>> _queryLists() async {
    final rows = await _db.query(
      'shopping_lists',
      orderBy: 'fecha DESC',
    );
    return rows.map(ShoppingList.fromMap).toList();
  }

  Future<List<ShoppingListItem>> _queryItems() async {
    final rows = await _db.query(
      'shopping_list_items',
      orderBy: 'id',
    );
    return rows.map(ShoppingListItem.fromMap).toList();
  }

  Future<List<ListLine>> _queryDetail(int idLista) async {
    final rows = await _db.rawQuery(
      '''
      SELECT sli.id, sli.id_lista, sli.id_producto, sli.cantidad,
             p.nombre, p.precio_unitario, p.activo
      FROM shopping_list_items sli
      JOIN products p ON p.id = sli.id_producto
      WHERE sli.id_lista = ?
      ORDER BY p.nombre COLLATE NOCASE
      ''',
      [idLista],
    );
    return rows.map(ListLine.fromMap).toList();
  }

  Future<List<String>> _queryStores() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT tienda FROM products ORDER BY tienda COLLATE NOCASE',
    );
    return rows.map((row) => row['tienda'] as String).toList();
  }
}