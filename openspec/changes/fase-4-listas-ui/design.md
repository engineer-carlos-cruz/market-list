## Context

Fases 1–2 dejaron las tablas v1 (`products`, `shopping_lists`, `shopping_list_items`), los modelos y `ShoppingListRepository` con `insert`, `insertItem`, `watchAll`, `watchAllItems`. Fase 3 dejó la UI de productos sobre `go_router`, declarando como Non-Goal el shell inferior (Productos | Listas) "para la fase de UI de listas". Hoja de ruta: ver proposal.md — Why.

Restricciones que condicionan el diseño:

- `productProvider` solo expone productos activos, pero la spec de fase 1 exige que una lista siga mostrando nombre y precio de productos deshabilitados → el detalle de lista necesita su propia lectura con JOIN, no puede depender de `productProvider`.
- `ShoppingListRepository` hoy no tiene mutaciones de ítem ni consultas por lista → el detalle no se puede construir sin operaciones nuevas.
- Cada repositorio mantiene su propia señal de cambio en un `Expando` por instancia de DB; la del detalle debe re-emitir también cuando cambia el catálogo (precios vigentes) → requiere unificar la señal.

## Goals / Non-Goals

**Goals:**
- Navegación inferior Productos | Listas sin tocar las rutas de producto existentes ni `main.dart`.
- Detalle de lista reactivo (ítems + producto, incluidos deshabilitados) reutilizable por la UI y el total.
- Mutaciones desde la UI que refrescan `shoppingListProvider` y el detalle automáticamente, mismo patrón que fase 3 (widgets construyen el repositorio al mutar).
- Total en vivo derivado del detalle, con moneda es_ES reutilizando el formato de productos.
- Sin cambios de esquema DB (v1) ni dependencias nuevas.

**Non-Goals:**
- Editar tienda/fecha de una lista existente, ni eliminar listas completas (no pedido en la fase; borrar ítems sí entra).
- Filtrar los productos agregables por la tienda de la lista (coincidencia de strings frágil; el catálogo es la fuente) — se deja anotado como pregunta abierta.
- Rehabilitar productos deshabilitados desde la UI.
- Migración de esquema: las tablas v1 ya cubren todo el modelo.

## Decisions

### 1. Unificar la señal de cambio por base entre repositorios
Hoy `ProductRepository` y `ShoppingListRepository` tienen un `Expando<StreamController>` privado cada uno, emitido solo por sus propias mutaciones. El detalle de lista necesita re-emitir ante mutaciones de ítems Y cambios del catálogo. Se extrae un único bus compartido por instancia de DB (un helper con `Expando<StreamController<void>>` keyed por `Database`) que ambos repositorios publican y consumen.

- `watchAll`/`watchAllItems`/`watchListDetail`/`watchStores` re-emiten sobre ese bus: cualquier mutación (de cualquier tabla) dispara re-query.
- Efecto colateral: `productProvider` también re-emite ante mutaciones de listas. Aceptado: queries locales baratas, single-user; ver Riesgos.
- Alternativa descartada: fusionar dos streams por tabla con `StreamGroup` de `package:async` → agrega una dependencia directa nueva para resolver algo que el bus compartido resuelve sin dependencias.

### 2. Nuevas operaciones de `ShoppingListRepository` (sin cambio de esquema)
- `updateItem(ShoppingListItem)` → `UPDATE shopping_list_items SET cantidad` por id; valida `cantidad > 0` (si no, lanza). Re-emite el bus.
- `removeItem(int id)` → `DELETE` del ítem (los ítems son filas de compra, sin historial; el borrado suave vive solo en `products`). Re-emite el bus.
- `watchListDetail(int idLista)` → `Stream<List<ListLine>>`, JOIN `shopping_list_items sli` + `products p` por `sli.id_producto = p.id`, filtrado por `sli.id_lista`, `ORDER BY p.nombre COLLATE NOCASE`. Incluye productos con `activo = 0` (su nombre y precio se conservan por spec de fase 1). Emisión inicial + re-emisión sobre el bus.
- `watchStores()` → `Stream<List<String>>`, `SELECT DISTINCT tienda FROM products ORDER BY tienda COLLATE NOCASE` (todo el catálogo, activos o no), emisión inicial + re-emisión sobre el bus.
- Bloqueo de duplicados en `insertItem`: antes de insertar, `SELECT count(*)` de `(id_lista, id_producto)`; si existe, lanza `ArgumentError` y no inserte. Hay una ventana teórica de carrera (TOCTOU) irrelevante en un app single-user local. Alternativa descartada: índice UNIQUE `(id_lista, id_producto)` vía migración v2 → cambia el esquema y la spec de fase 1 prometió v1 sin migraciones; el chequeo en repositorio es suficiente.

### 3. Modelo `ListLine` para el detalle (JOIN aplanado)
Nuevo `lib/data/models/list_line.dart`: campos `id` (de ítem), `idLista`, `idProducto`, `nombre`, `precioUnitario`, `cantidad`, `activo`. `fromMap` lee el fila del JOIN. La UI y el total consumen este objeto plano (no anidamiento ítem+producto). Naming en inglés como los modelos existentes (`Product`, `ShoppingList`, `ShoppingListItem`). Alternativa descartada: composición `{item, product}` — dos saltos en la UI para mostrar nombre/precio, cuando el JOIN entrega la fila lista.

### 4. Shell inferior con `StatefulShellRoute` en `router.dart`
`go_router` pasa a dos ramas dentro de un `StatefulShellRoute.indexedStack`, cada una con su `Scaffold` + `NavigationBar`: **Productos** (`/productos` y sus sub-rutas, intactas) y **Listas** (`/listas`, `listas/:id`). `main.dart` no cambia (`MaterialApp.router` ya apunta a `appRouter`). `initialLocation` sigue `/productos`.

- Rutas en español (convención del proyecto), incluyendo `/listas/:id`; el comentario de `config.yaml` con `/lists/:id` se interpreta como nota histórica, no como convención vigente de rutas (las rutas reales son `/productos`).
- Fase 3 marcó explícitamente este shell como trabajo de esta fase; no introduce reestructuración de la raíz.

### 5. Creación de lista: selector editable de tienda derivada del catálogo
`CrearListaScreen` (pantalla completa, patrón fase 3) con un `DropdownMenu<String>` de Material: muestra las tiendas de `storeProvider` como sugerencias y permite escribir una tienda nueva (stock de Flutter, sin paquete visual). Validación: tienda no vacía (trim). Al guardar, `ShoppingList(tienda, fecha: DateTime.now())` vía `repo.insert`; el bus refresca `shoppingListProvider` y la lista aparece. Si el catálogo está vacío, el `DropdownMenu` queda sin sugerencias y el usuario escribe la tienda.

- Alternativa descartada: campo texto libre puro (pierde la "selección" que pide la fase) y dropdown cerrado (impide tiendas nuevas sin productos previos).

### 6. Detalle de lista y total en vivo
`ListaDetalleScreen` (ruta `/listas/:id`):
- Header con tienda y fecha formateada (`intl`, `DateFormat('d MMM yyyy', 'es_ES')`; el copy exacto se ajusta en implementación).
- Botón "Agregar producto" → `AgregarProductoScreen`: lista de productos activos (`productProvider`) con búsqueda por nombre; los ya presentes en la lista (según `ListLine.idProducto`) se muestran deshabilitados/con check (no duplicados). Tap → `repo.insertItem` (cantidad 1); el bus refresca el detalle.
- Filas: nombre + precio unitario + stepper `-` / cantidad / `+` (widget propio). `+` → `repo.updateItem(cantidad+1)`. `-`: si cantidad > 1 → `updateItem(cantidad-1)`; si cantidad == 1 → `AlertDialog` de confirmación y, al confirmar, `repo.removeItem(id)`.
- Total: barra persistente en el `bottomNavigationBar` del Scaffold del detalle, `total = sum(cantidad * precioUnitario)` sobre `ListLine`, formateada con `formatoMoneda`. Se recalcula en cada emisión del stream (vivacidad por reactividad, no por setState manual).

### 7. Providers nuevos y formateador compartido
- `shoppingListDetailProvider = StreamProvider.family<List<ListLine>, int>` → `repo.watchListDetail(id)`.
- `storeProvider = StreamProvider<List<String>>` → `repo.watchStores()`.
- Se conservan `shoppingListProvider` y `shoppingListItemProvider`.
- Nuevo `lib/ui/formatos.dart` con `String formatoMoneda(double)` (`NumberFormat('#,##0.00', 'es_ES')`, prefijo `$`), y `formatPrecio` de `productos_screen.dart` delega en él para no duplicar la lógica de formato entre pantallas.

### 8. Tests por capa (patrón fases 1–3)
Reutilizando `openInMemoryDatabase`, `ProviderContainer` y los helpers de widget de fase 3:
- Repositorio: `updateItem` (positivo e inválido), `removeItem`, duplicados bloqueados, `watchListDetail` (orden por nombre, incluye deshabilitados, re-emite ante mutación de ítem y ante cambio de producto), `watchStores` (distinct + orden + refresco).
- Providers: `shoppingListDetailProvider` y `storeProvider` emiten y refrescan.
- Widgets: `ListasScreen` (vacío, listado tienda+fecha, navegación al detalle), `CrearListaScreen` (sugerencias, tienda nueva, validación), `ListaDetalleScreen` (alta con duplicados deshabilitados, stepper +/-, confirmación y borrado, total que se actualiza).

## Risks / Trade-offs

- [Señal unificada hace que `productProvider` re-emita ante mutaciones de listas] → Re-query local barato y single-user; se acepta. Si algún día molesta, se vuelve a separar por tabla y el detalle lo combina.
- [El detalle re-queries el JOIN completo en cada mutación] → Volumen local chico (lista de mercado); consistente con la decisión de re-query de fases 1–2.
- [`DropdownMenu` editable exige una convención de copy del "estado sin catálogo"] → Pantalla con mensaje guiando a escribir la tienda; se resuelve con copy de UI sin alterar specs.
- [Bloqueo de duplicados por `count(*)` tiene carrera teórica] → Single-user local; irrelevante. Alternativa (índice UNIQUE) exige migración, fuera de alcance.
- [Rutas en español vs. `/lists/:id` del contexto] → Se adopta `/listas/:id` por la convención real del código (`/productos`); el shell se agrega sin reescribir rutas de productos.

## Migration Plan

- Sin cambios de esquema DB ni migración; no hay estado persistido que migrar.
- `main.dart` intacto; el cambio se concentra en `router.dart` (shell inferior) y nuevas rutas. Las rutas `/productos*` conservan sus nombres.
- Rollback: revertir el commit; la app vuelve a arrancar en `/productos` sin shell y sin pérdida de datos.

## Open Questions

- Filtrar en `AgregarProductoScreen` los productos por la tienda de la lista (haría match exacto de strings `tienda`): hoy se ofrecen todos los activos; filtrar es un refinamiento futuro sin impacto en specs ni tareas actuales.
- Formato de fecha exacto en listado y header (corto vs. largo): se define con copy de UI en la implementación.