import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/state/providers/database_provider.dart';
import 'package:sqflite/sqflite.dart';

ProviderContainer createTestContainer(Database db) {
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWith((ref) async => db),
  ]);
  addTearDown(container.dispose);
  return container;
}

ProviderSubscription<AsyncValue<T>> listenTo<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
  List<T> values,
) {
  final sub = container.listen(provider, (prev, next) {
    if (next.hasValue) values.add(next.value as T);
  });
  addTearDown(sub.close);
  return sub;
}

Future<List<T>> waitForValues<T>(
  List<T> values,
  bool Function(List<T>) condition, {
  Duration timeout = const Duration(seconds: 3),
  String? message,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition(values)) {
    if (DateTime.now().isAfter(deadline)) {
      fail(message ?? 'Timeout esperando emisiones; recibidas ${values.length}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return List.of(values);
}