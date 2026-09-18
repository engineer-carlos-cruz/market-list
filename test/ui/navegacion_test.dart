import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_list/ui/listas/listas_screen.dart';
import 'package:market_list/ui/productos/productos_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('la ruta raíz / redirige a la rama Listas', (tester) async {
    await pumpAppWithDb(tester, db);

    expect(find.byType(ProductosScreen), findsOneWidget);

    final context = tester.element(find.byType(NavigationBar));
    GoRouter.of(context).go('/');
    await tester.pumpAndSettle();

    expect(find.byType(ListasScreen), findsOneWidget);
    expect(find.text('Aún no hay listas'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}