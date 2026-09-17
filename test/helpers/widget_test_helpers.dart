import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:market_list/data/database/app_database.dart';
import 'package:market_list/router.dart';
import 'package:market_list/state/providers/database_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openInMemoryDatabaseForWidgets() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  return AppDatabase.instance.open(inMemoryDatabasePath);
}

Future<ProviderScope> pumpWithDb(
  WidgetTester tester,
  Database db,
  Widget child,
) async {
  await initializeDateFormatting('es_ES');
  final scope = ProviderScope(
    overrides: [databaseProvider.overrideWith((ref) async => db)],
    child: MaterialApp(home: child),
  );
  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
  return scope;
}

Finder destinoListas() => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Listas'),
    );

Future<ProviderScope> pumpAppWithDb(
  WidgetTester tester,
  Database db,
) async {
  await initializeDateFormatting('es_ES');
  final scope = ProviderScope(
    overrides: [databaseProvider.overrideWith((ref) async => db)],
    child: MaterialApp.router(
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
    ),
  );
  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
  return scope;
}