import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/app_database.dart';

final databaseProvider = FutureProvider<Database>((ref) {
  return AppDatabase.instance.database;
});