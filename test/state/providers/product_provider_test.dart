import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/state/providers/product_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/in_memory_database.dart';
import '../../helpers/provider_container.dart';

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

  test('emite los productos activos al suscribirse', () async {
    await repo.insert(const Product(
      nombre: 'Leche',
      precioUnitario: 12.5,
      tienda: 'Tienda A',
    ));
    final id = await repo.insert(const Product(
      nombre: 'Arroz',
      precioUnitario: 10,
      tienda: 'Tienda B',
    ));
    await repo.disable(id);
    final container = createTestContainer(db);
    final values = <List<Product>>[];
    listenTo(container, productProvider, values);

    await waitForValues(values, (v) => v.isNotEmpty);

    expect(values.last.map((p) => p.nombre), ['Leche']);
  });

  test('se refresca tras insertar un producto', () async {
    final container = createTestContainer(db);
    final values = <List<Product>>[];
    listenTo(container, productProvider, values);

    await waitForValues(values, (v) => v.isNotEmpty);
    expect(values.last, isEmpty);

    await repo.insert(const Product(
      nombre: 'Manzana',
      precioUnitario: 3,
      tienda: 'Verdulería',
    ));
    await waitForValues(
      values,
      (v) => v.isNotEmpty && v.last.isNotEmpty,
      message: 'Timeout esperando emisión con la manzana',
    );

    expect(values.last.map((p) => p.nombre), ['Manzana']);
  });
}