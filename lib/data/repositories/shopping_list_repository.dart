import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';

class ShoppingListRepository {
  ShoppingListRepository(this._db) : _changes = _changesFor(_db);

  final Database _db;

  static final Expando<StreamController<void>> _changesByDatabase =
      Expando<StreamController<void>>('shopping_list_changes');

  final StreamController<void> _changes;

  static StreamController<void> _changesFor(Database db) {
    final existing = _changesByDatabase[db];
    if (existing != null) return existing;
    final changes = StreamController<void>.broadcast();
    _changesByDatabase[db] = changes;
    return changes;
  }

  Future<int> insert(ShoppingList list) async {
    final id = await _db
        .insert('shopping_lists', list.toMap(withId: false));
    _changes.add(null);
    return id;
  }

  Future<int> insertItem(ShoppingListItem item) async {
    final id = await _db
        .insert('shopping_list_items', item.toMap(withId: false));
    _changes.add(null);
    return id;
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
}