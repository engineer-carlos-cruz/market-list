import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/shopping_list_repository.dart';
import 'database_provider.dart';

final storeProvider = StreamProvider<List<String>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  final repo = ShoppingListRepository(db);
  yield* repo.watchStores();
});