## 1. Datos — modelos de listas

- [x] 1.1 Crear `lib/data/models/shopping_list.dart`: clase `ShoppingList` inmutable (`id`, `tienda`, `fecha` como `DateTime`) con `fromMap`/`toMap` (fecha en ISO-8601), `copyWith` y `==`/`hashCode`; verificar que `flutter analyze` pasa sin warnings
- [x] 1.2 Crear `lib/data/models/shopping_list_item.dart`: clase `ShoppingListItem` inmutable (`id`, `idLista`, `idProducto`, `cantidad`) con `fromMap`/`toMap`, `copyWith` y `==`/`hashCode`; verificar que `flutter analyze` pasa sin warnings

## 2. Datos — repositorio de listas

- [x] 2.1 Crear `lib/data/repositories/shopping_list_repository.dart` con `StreamController<void>.broadcast()` compartido e implementar `insert(ShoppingList) -> int` (INSERT + `lastInsertId` en `shopping_lists`) emitiendo la señal de cambio; verificar con test unitario que devuelve un id único y persiste la lista
- [x] 2.2 Implementar `insertItem(ShoppingListItem) -> int` (INSERT en `shopping_list_items` con FK válido y cantidad positiva) emitiendo la señal de cambio; verificar con test que persiste el ítem y devuelve su id
- [x] 2.3 Implementar `watchAll(): Stream<List<ShoppingList>>` con emisión inicial y re-query por señal, ordenado por `fecha DESC`; verificar por test que emite el estado inicial y que una emisión nueva sigue a cada mutación de lista o de ítem
- [x] 2.4 Implementar `watchAllItems(): Stream<List<ShoppingListItem>>` con emisión inicial y re-query por señal, ordenado por `id`; verificar por test que emite el estado inicial y se refresca tras cada alta de ítem

## 3. Estado — providers Riverpod

- [x] 3.1 Crear `lib/state/providers/database_provider.dart`: `FutureProvider<Database>` sobre `AppDatabase.instance.database`; verificar que compila y expone la DB abierta en un test de humo con `ProviderContainer`
- [x] 3.2 Crear `lib/state/providers/product_provider.dart`: `StreamProvider<List<Product>>` que resuelve `databaseProvider.future` y delega en `ProductRepository.watchAll()`; verificar con test en `ProviderContainer` que emite productos activos y se refresca tras insertar
- [x] 3.3 Crear `lib/state/providers/shopping_list_provider.dart` y `lib/state/providers/shopping_list_item_provider.dart`: `StreamProvider<List<ShoppingList>>` y `StreamProvider<List<ShoppingListItem>>` sobre `ShoppingListRepository`; verificar con tests en `ProviderContainer` emisión inicial y refresco tras alta de lista/ítem
- [x] 3.4 Envolver `main.dart` en `ProviderScope` (sin UI nueva) y verificar que `flutter analyze` pasa y la app compila

## 4. Verificación final

- [x] 4.1 Ejecutar `flutter analyze` y confirmar cero errores y cero warnings en `lib/` y `test/`
- [x] 4.2 Ejecutar `flutter test` y confirmar que toda la suite pasa (incluidos tests de fase 1); confirmar que ni `app_database.dart` ni el esquema DB fueron modificados