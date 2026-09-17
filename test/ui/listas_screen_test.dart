import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:market_list/data/models/shopping_list.dart';
import 'package:market_list/data/repositories/shopping_list_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;
  late ShoppingListRepository repo;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
    repo = ShoppingListRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Navegación inferior', () {
    testWidgets('el shell muestra las pestañas Productos y Listas',
        (tester) async {
      await pumpAppWithDb(tester, db);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Productos'), findsWidgets);
      expect(find.text('Listas'), findsWidgets);
    });

    testWidgets('la pestaña Listas muestra el estado vacío de listado',
        (tester) async {
      await pumpAppWithDb(tester, db);

      await tester.tap(destinoListas());
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay listas'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });

  group('Listado', () {
    testWidgets('muestra las listas ordenadas con tienda y fecha formateada',
        (tester) async {
      final fechaReciente = DateTime(2026, 9, 13);
      await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: fechaReciente,
      ));
      await repo.insert(ShoppingList(
        tienda: 'Feria',
        fecha: DateTime(2026, 9, 10),
      ));

      await pumpAppWithDb(tester, db);
      await tester.tap(destinoListas());
      await tester.pumpAndSettle();

      final fechaFinal = DateFormat('d MMM yyyy', 'es_ES').format(fechaReciente);
      expect(find.text('Mercado Central'), findsOneWidget);
      expect(find.text(fechaFinal), findsOneWidget);
      expect(find.text('Feria'), findsOneWidget);

      final firstTileY = tester.getTopLeft(find.text('Mercado Central')).dy;
      final secondTileY = tester.getTopLeft(find.text('Feria')).dy;
      expect(firstTileY, lessThan(secondTileY));
    });

    testWidgets('tocar una lista navega a su detalle', (tester) async {
      await repo.insert(ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 13),
      ));

      await pumpAppWithDb(tester, db);
      await tester.tap(destinoListas());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mercado Central'));
      await tester.pumpAndSettle();

      expect(find.text('La lista está vacía'), findsOneWidget);
      expect(find.byTooltip('Agregar producto'), findsOneWidget);
    });

    testWidgets('el FAB conduce a la creación de una lista', (tester) async {
      await pumpAppWithDb(tester, db);
      await tester.tap(destinoListas());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva lista'), findsOneWidget);
    });
  });
}