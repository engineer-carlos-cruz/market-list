import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('crea la base version 1 con las tres tablas esperadas', () async {
    expect(await db.getVersion(), 1);

    final tables =
        await db.query('sqlite_master', where: "type = 'table'");
    final names = tables.map((t) => t['name']).toSet();
    expect(names, containsAll({'products', 'shopping_lists', 'shopping_list_items'}));
  });

  test('activa la verificación de foreign keys', () async {
    final result = await db.rawQuery('PRAGMA foreign_keys');
    expect(result.first.values.first, 1);
  });
}