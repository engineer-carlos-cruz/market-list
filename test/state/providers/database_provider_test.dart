import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/state/providers/database_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';
import '../../helpers/provider_container.dart';

void main() {
  test('expone la base local ya abierta', () async {
    final db = await openInMemoryDatabase();
    final container = createTestContainer(db);

    final exposed = await container.read(databaseProvider.future);

    expect(exposed, same(db));
    expect(await exposed.getVersion(), 1);
  });
}