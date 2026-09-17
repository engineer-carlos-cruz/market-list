import 'dart:async';

import 'package:sqflite/sqflite.dart';

class DatabaseChanges {
  DatabaseChanges._();

  static final Expando<StreamController<void>> _byDatabase =
      Expando<StreamController<void>>('database_changes');

  static StreamController<void> forDb(Database db) {
    final existing = _byDatabase[db];
    if (existing != null) return existing;
    final controller = StreamController<void>.broadcast();
    _byDatabase[db] = controller;
    return controller;
  }
}