## 1. Datos: bus de cambios y operaciones del repositorio

- [x] 1.1 Extraer un bus de cambios único por instancia de DB (helper con `Expando<StreamController<void>>` keyed por `Database`) y que `ProductRepository` y `ShoppingListRepository` publiquen/consuman el mismo bus; verificar que los tests existentes de ambos repositorios siguen en verde (`flutter test`) y que `flutter analyze` no reporta errores
- [x] 1.2 Crear el modelo `ListLine` (`lib/data/models/list_line.dart`) con `fromMap` para la fila del JOIN (id de ítem, idLista, idProducto, nombre, precioUnitario, cantidad, activo) y verificar que su test de mapeo de fila SQL pasa
- [x] 1.3 Implementar `updateItem(ShoppingListItem)` que actualiza `cantidad`, rechaza `cantidad <= 0` (lanza) y re-emite el bus; agregar tests de repositorio para cantidad válida e inválida y verificar que pasan
- [x] 1.4 Implementar `removeItem(int id)` que elimina el ítem y re-emite el bus; agregar test de repositorio que verifica la eliminación y el refresco del stream de ítems y verificar que pasa
- [x] 1.5 Implementar `watchListDetail(int idLista)` con JOIN `shopping_list_items` + `products`, ordenado por nombre COLLATE NOCASE, incluyendo productos deshabilitados; agregar tests que cubren orden, inclusión de deshabilitados y re-emisión ante mutación de ítem y ante cambio de producto, y verificar que pasan
- [x] 1.6 Implementar `watchStores()` (`SELECT DISTINCT tienda FROM products` ordenado sin repetidos) y verificar con test que emite el estado inicial y se refresca ante cambios del catálogo
- [x] 1.7 Hacer que `insertItem` rechace un `(id_lista, id_producto)` ya presente (lanza sin insertar) y verificar con test que aborta el duplicado y conserva el stream intacto

## 2. Estado: providers nuevos

- [x] 2.1 Crear `shoppingListDetailProvider` (`StreamProvider.family<List<ListLine>, int>`) sobre `watchListDetail` y verificar con test de provider que emite el detalle y re-emite tras una mutación
- [x] 2.2 Crear `storeProvider` (`StreamProvider<List<String>>`) sobre `watchStores` y verificar con test de provider que emite las tiendas y se refresca con el catálogo

## 3. UI: formateador, navegación y pantallas

- [x] 3.1 Crear `lib/ui/formatos.dart` con `formatoMoneda(double)` (es_ES, `$1.234,56`) y delegar `formatPrecio` de `productos_screen.dart` a él; verificar que los tests de la pantalla de productos siguen pasando
- [x] 3.2 Convertir `router.dart` a `StatefulShellRoute.indexedStack` con ramas Productos (`/productos*`) y Listas (`/listas`, `/listas/:id`) sin renombrar rutas de producto; verificar que `flutter analyze` pasa y que un widget test de navegación monta el shell y muestra ambas pestañas
- [x] 3.3 Implementar `ListasScreen` (listado reactivo con tienda y fecha formateada, estado vacío, FAB de creación, navegación al detalle al tocar una lista) y verificar con widget tests que pinta listado, maneja el vacío y navega
- [x] 3.4 Implementar `CrearListaScreen` con `DropdownMenu` editable de tiendas desde `storeProvider`, tienda nueva permitida, validación de tienda no vacía y guardado que inserta con `fecha = DateTime.now()`; verificar con widget tests selección, tienda nueva, validación y que la lista aparece en el listado
- [x] 3.5 Implementar `ListaDetalleScreen` (header tienda + fecha) y `AgregarProductoScreen` (búsqueda por nombre sobre `productProvider`, con los ya incluidos deshabilitados/marcados y alta con cantidad 1); verificar con widget tests la alta de un producto y el bloqueo visual de duplicados
- [x] 3.6 Implementar la fila con stepper (`-` / cantidad / `+`), con `-` en cantidad 1 abriendo el diálogo de confirmación de borrado y `removeItem` al confirmar; verificar con widget tests incremento, decremento, confirmación y cancelación de borrado
- [x] 3.7 Agregar el total en vivo como barra persistente del detalle (`sum(cantidad * precioUnitario)` de `ListLine` con `formatoMoneda`), que se actualiza con cada emisión del stream; verificar con widget tests que el total refleja altas, cambios de cantidad y borrados con el formato `$X.XXX,XX`

## 4. Integración y verificación final

- [x] 4.1 Correr `flutter analyze` sin warnings y `flutter test` con toda la suite en verde
- [x] 4.2 Verificar el flujo completo de forma manual o con widget test integrado: crear lista con tienda nueva desde la pestaña Listas, agregar productos desde el catálogo, ajustar cantidades con stepper, borrar un ítem con confirmación y comprobar que el total se actualiza en vivo y con formato de moneda