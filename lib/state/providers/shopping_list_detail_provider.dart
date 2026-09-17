import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/list_line.dart';
import '../../data/repositories/shopping_list_repository.dart';
import 'database_provider.dart';

final shoppingListDetailProvider =
    StreamProvider.family<List<ListLine>, int>((ref, idLista) async* {
  final db = await ref.watch(databaseProvider.future);
  final repo = ShoppingListRepository(db);
  yield* repo.watchListDetail(idLista);
});