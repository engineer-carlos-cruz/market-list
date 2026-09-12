## Why

La fase 1 dejó la capa de datos (esquema SQLite + repositorio de productos con `Stream<List<Product>>`), pero la app sigue en `main.dart` con "Hello World": no hay capa de estado. Fase 2 introduce la capa Riverpod que expone los flujos reactivos de productos y listas de compra a la futura UI, de modo que cualquier mutación de la DB se refleje sola en pantalla. Además completa el dominio de listas (modelos y repositorio) que la tabla `shopping_lists`/`shopping_list_items` ya esperaba desde el esquema v1.

## What Changes

- **Capa de estado Riverpod** (`lib/state/providers/`):
  - `databaseProvider`: expone la base de datos (`FutureProvider<Database>` sobre `AppDatabase.instance`).
  - `productProvider`: `StreamProvider<List<Product>>` con los productos activos del repositorio.
  - `shoppingListProvider`: `StreamProvider<List<ShoppingList>>` con las listas de compra.
  - `shoppingListItemProvider`: `StreamProvider<List<ShoppingListItem>>` con los ítems de todas las listas (un provider por entidad, según decisión de exploración).
- **Modelos nuevos**: `ShoppingList` (id, tienda, fecha) y `ShoppingListItem` (id, idLista, idProducto, cantidad) con `fromMap`/`toMap`, `copyWith` y valor-igualdad, siguiendo el patrón de `Product`.
- **Repositorio nuevo**: `ShoppingListRepository` con `insert(lista)`, `insertItem(item)` y streams reactivos `watchAll()`/`watchAllItems()` (mismo patrón broadcast + re-query que `ProductRepository`).
- **Cableado en `main.dart`**: envolver la app con `ProviderScope` para que los providers estén disponibles y se inicialicen. No hay pantallas nuevas en esta fase.
- **Tests**: repositorio de listas en memoria y tests de providers en `ProviderContainer` con la DB en memoria overrideada.

## Capabilities

### New Capabilities
- `shopping-lists`: dominio de listas de compra — modelos `ShoppingList`/`ShoppingListItem` y repositorio con streams reactivos (`watchAll` de listas y de ítems) listos para la capa de estado.
- `state`: capa de estado Riverpod — providers reactivos (`databaseProvider`, `productProvider`, `shoppingListProvider`, `shoppingListItemProvider`) que exponen streams y se refrescan automáticamente ante mutaciones de la base local.

### Modified Capabilities
- Ninguna: la reactividad de `products` (stream ordenado por nombre) ya quedó especificada en fase 1; el provider que la expone a la UI pertenece a la nueva capability `state`.

## Impact

- **Nuevos archivos**: `lib/state/providers/database_provider.dart`, `lib/state/providers/product_provider.dart`, `lib/state/providers/shopping_list_provider.dart`, `lib/state/providers/shopping_list_item_provider.dart`, `lib/data/models/shopping_list.dart`, `lib/data/models/shopping_list_item.dart`, `lib/data/repositories/shopping_list_repository.dart` (más tests correspondientes).
- **Modificados**: `lib/main.dart` (envuelto en `ProviderScope`, sin UI nueva) y `lib/data/repositories/product_repository.dart` (señal de cambio compartida por instancia de base, ver `design.md` decisión 2).
- **Dependencias**: ninguna nueva (flutter_riverpod 2.6.1 ya está declarado; test en memoria con `sqflite_common_ffi` ya disponible como dev_dependency).
- **Esquema DB**: sin cambios de esquema ni migración — las tablas ya existen desde v1.
- **Sin red**: todo queda 100% local.