import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'database_provider.dart';

final productProvider = StreamProvider<List<Product>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  final repo = ProductRepository(db);
  yield* repo.watchAll();
});