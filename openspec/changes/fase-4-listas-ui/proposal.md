## Why

Fases 1–3 dejaron la base local (tablas v1), el estado reactivo y la gestión de productos desde la UI, pero todavía no hay forma de armar una compra real: la app no permite crear una lista por tienda, cargar productos con cantidades ni ver cuánto sale. Fase 4 cierra el ciclo de compra con la gestión completa de listas de compra desde la UI.

## What Changes

- **Pantalla Listas**: listado reactivo de las listas guardadas mostrando tienda y fecha (usando `intl` para el formato de fecha), con acción de creación (FAB) que abre un selector de tienda.
- **Creación de lista seleccionando tienda**: selector que ofrece las tiendas existentes derivadas del catálogo de productos (`DISTINCT tienda`) y permite ingresar una tienda nueva; la fecha se fija a la actual al crear.
- **Navegación inferior Productos | Listas**: `StatefulShellRoute` con dos ramas, diferido explícitamente por fase 3 para esta fase. `main.dart` no cambia (el shell vive en `router.dart`); `/productos` queda intacto y se agregan `/listas` y `/listas/:id`.
- **Detalle de lista**: pantalla para una lista concreta — header con tienda y fecha, alta de productos desde el catálogo activo (con marcado de los ya incluidos, sin duplicados) y filas con cantidad editable mediante stepper.
- **Stepper con semántica de borrado**: los botones `-` / `+` ajustan cantidad entre 1 y un tope; decrementar en cantidad 1 abre confirmación de borrado del ítem.
- **Total en vivo**: barra persistente que muestra `sum(cantidad * precio_unitario)` de la lista, formateado con `intl` es_ES (`$1.234,56`), reutilizando el formato de `formatPrecio`.
- **Repositorio de listas ampliado**: nuevas operaciones de mutación de ítems (actualizar cantidad, eliminar), stream de detalle por lista con join a producto (incluye productos deshabilitados, que siguen mostrando nombre y precio según spec de fase 1), y derivación de tiendas del catálogo.
- **Sin cambios de esquema**: las tablas v1 cubren todo; no hay migración. Duplicados de producto por lista se bloquean a nivel repositorio. Sin dependencias de red.

## Capabilities

### New Capabilities
- `shopping-list-management`: gestión de listas de compra desde la UI — pantalla de listado (tienda + fecha) con navegación inferior, creación con selección de tienda, detalle de lista con altas de productos, stepper de cantidad y total en vivo con moneda.

### Modified Capabilities
- `shopping-lists`: el comportamiento de datos del dominio se amplía — mutaciones de ítems (cantidad y borrado), detalle reactivo por lista con nombre y precio del producto (incluso deshabilitados), derivación de tiendas del catálogo y bloqueo de duplicados.

## Impact

- **Nuevos archivos**: `lib/ui/listas/` (pantalla de listas, detalle, selector de tienda, filas con stepper), modelo de línea de lista (ítem + producto) para el detalle, providers de detalle/tiendas, y tests por capa.
- **Modificados**: `lib/router.dart` (shell inferior + rutas `/listas` y `/listas/:id`), `lib/data/repositories/shopping_list_repository.dart` (nuevas operaciones y streams), `lib/state/providers/*` (providers nuevos para detalle y tiendas), `lib/ui/productos/*` solo si hace falta un ajuste mínimo para convivir con el shell (no se espera).
- **Dependencias**: ninguna nueva — `intl` y `go_router` ya están declarados; UI con stock de Material.
- **Esquema DB**: sin cambios ni migración (v1); el bloqueo de duplicados se resuelve en el repositorio.
- **Sin red**: todo sigue 100% local.