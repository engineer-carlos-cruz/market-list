import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';
import 'package:market_list/data/repositories/product_repository.dart';
import 'package:market_list/ui/productos/producto_form_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ProductRepository repo;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    repo = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Validación', () {
    Future<void> guardar(WidgetTester tester) async {
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    testWidgets('campos obligatorios muestran error y no persisten',
        (tester) async {
      await pumpWithDb(tester, db, const ProductoFormScreen());

      await guardar(tester);

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('La tienda es obligatoria'), findsOneWidget);
      expect(find.text('Ingresa un precio válido'), findsOneWidget);

      final rows = await db.query('products');
      expect(rows, isEmpty);
    });

    testWidgets('precio menor o igual a cero muestra error y no persiste',
        (tester) async {
      await pumpWithDb(tester, db, const ProductoFormScreen());

      await tester.enterText(find.byKey(const Key('campo-nombre')), 'Leche');
      await tester.enterText(find.byKey(const Key('campo-precio')), '0');
      await tester.enterText(find.byKey(const Key('campo-tienda')), 'Tienda A');
      await guardar(tester);

      expect(find.text('El precio debe ser mayor a cero'), findsOneWidget);
      final rows = await db.query('products');
      expect(rows, isEmpty);
    });
  });

  group('Alta', () {
    testWidgets('guarda un producto válido y vuelve al listado',
        (tester) async {
      await pumpAppWithDb(tester, db);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo-nombre')), 'Leche');
      await tester.enterText(find.byKey(const Key('campo-precio')), '12,5');
      await tester.enterText(find.byKey(const Key('campo-tienda')), 'Tienda A');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Leche'), findsOneWidget);
      expect(find.text('\$12,50'), findsOneWidget);
      expect(find.text('Tienda A'), findsOneWidget);

      final rows = await db.query('products');
      expect(rows, hasLength(1));
      expect(rows.single['nombre'], 'Leche');
      expect(rows.single['precio_unitario'], 12.5);
      expect(rows.single['tienda'], 'Tienda A');
      expect(rows.single['activo'], 1);
    });

    testWidgets('acepta precio con separador de miles es_ES', (tester) async {
      await pumpAppWithDb(tester, db);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('campo-nombre')), 'Café');
      await tester.enterText(
          find.byKey(const Key('campo-precio')), '1.234,56');
      await tester.enterText(
          find.byKey(const Key('campo-tienda')), 'Tienda B');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('\$1.234,56'), findsOneWidget);

      final rows = await db.query('products');
      expect(rows, hasLength(1));
      expect(rows.single['precio_unitario'], 1234.56);
    });
  });

  group('Edición', () {
    testWidgets('precarga los datos del producto', (tester) async {
      await repo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
      await pumpAppWithDb(tester, db);

      await tester.tap(find.text('Leche'));
      await tester.pumpAndSettle();

      expect(find.text('Editar producto'), findsOneWidget);
      final nombre = tester.widget<TextFormField>(
        find.byKey(const Key('campo-nombre')),
      );
      final precio = tester.widget<TextFormField>(
        find.byKey(const Key('campo-precio')),
      );
      final tienda = tester.widget<TextFormField>(
        find.byKey(const Key('campo-tienda')),
      );
      expect(nombre.controller!.text, 'Leche');
      expect(precio.controller!.text, '12,5');
      expect(tienda.controller!.text, 'Tienda A');
    });

    testWidgets('guardar modifica el producto conservando id y estado',
        (tester) async {
      final id = await repo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
      await pumpAppWithDb(tester, db);

      await tester.tap(find.text('Leche'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('campo-nombre')), 'Leche Larga Vida');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Leche Larga Vida'), findsOneWidget);
      expect(find.text('Leche'), findsNothing);

      final rows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows, hasLength(1));
      expect(rows.single['nombre'], 'Leche Larga Vida');
      expect(rows.single['activo'], 1);
    });

    testWidgets('cancelar la edición no modifica nada', (tester) async {
      final id = await repo.insert(const Product(
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Tienda A',
      ));
      await pumpAppWithDb(tester, db);

      await tester.tap(find.text('Leche'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('campo-nombre')), 'Leche Larga Vida');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Leche'), findsOneWidget);
      expect(find.text('Leche Larga Vida'), findsNothing);

      final rows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.single['nombre'], 'Leche');
    });
  });
}