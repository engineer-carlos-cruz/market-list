import 'package:market_list/data/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openInMemoryDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return AppDatabase.instance.open(inMemoryDatabasePath);
}