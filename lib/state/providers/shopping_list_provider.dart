import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shopping_list.dart';
import '../../data/repositories/shopping_list_repository.dart';
import 'database_provider.dart';

final shoppingListProvider = StreamProvider<List<ShoppingList>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  final repo = ShoppingListRepository(db);
  yield* repo.watchAll();
});