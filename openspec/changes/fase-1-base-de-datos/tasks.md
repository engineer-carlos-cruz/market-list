## 1. Datos — modelo y esquema

- [ ] 1.1 Crear `lib/data/models/product.dart`: clase `Product` inmutable (`id, nombre, precio_unitario, tienda, activo`) con `fromMap`/`toMap` respetando snake_case → camelCase; verificar que `flutter analyze` pasa sin warnings
- [ ] 1.2 Crear `lib/data/database/app_database.dart`: singleton que abre `market_list.db` con `version: 1`, `PRAGMA foreign_keys = ON` en `onConfigure`, `_onCreate` creando las 3 tablas (`products` con `activo INTEGER NOT NULL DEFAULT 1`, `shopping_lists`, `shopping_list_items` con FKs y `cantidad INTEGER NOT NULL`), y `_onUpgrade` con switch por versión encadenado; verificar que la base se crea con las tablas esperadas en un test de humo
- [ ] 1.3 Exponer los `CREATE TABLE` en constantes reutilizables (consultables por `_onCreate` y futuras migraciones) y verificar que `flutter analyze` pasa

## 2. Datos — repositorio de productos

- [ ] 2.1 Implementar `ProductRepository.insert(Product) -> int` (INSERT + `lastInsertId`) y verificar con test unitario que devuelve un id único y persiste el registro activo
- [ ] 2.2 Implementar `ProductRepository.update(Product)` (UPDATE por id, sin tocar `activo`) y verificar con test que los datos cambian y el estado de habilitación se conserva
- [ ] 2.3 Implementar `disable(int id)` / `enable(int id)` (UPDATE `activo` 0/1) y verificar con tests que deshabilitar lo excluye y habilitar lo restaura conservando sus datos
- [ ] 2.4 Implementar el stream reactivo interno (broadcast de cambios tras cada mutación) y `watchAll()`: `Stream<List<Product>>` con `WHERE activo = 1`, emisión inicial y re-query ante cada señal; verificar por test que emite el estado inicial y que una emisión nueva sigue a cada mutación
- [ ] 2.5 Asegurar orden de `watchAll()` con `ORDER BY nombre COLLATE NOCASE` y verificar por test que el listado ordena sin distinguir mayúsculas/minúsculas

## 3. Infraestructura y suite de pruebas

- [ ] 3.1 Agregar `sqflite_common_ffi` como `dev_dependency` y crear helper de test que abra SQLite en memoria (`databaseFactoryFfi` + `inMemoryDatabasePath`) ejecutando el mismo `_onCreate` de `app_database.dart`; verificar que `flutter test` compila la suite
- [ ] 3.2 Escribir suite de tests del repositorio cubriendo: insert (id + persistencia), update, disable/enable, filtro de activos en `watchAll`, orden NOCASE y refresco tras mutación; verificar que `flutter test` pasa

## 4. Verificación final

- [ ] 4.1 Ejecutar `flutter analyze` y confirmar cero errores y cero warnings en `lib/` y `test/`
- [ ] 4.2 Ejecutar `flutter test` y confirmar que toda la suite pasa; confirmar que `main.dart` no fue modificado