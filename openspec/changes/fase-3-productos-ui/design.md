## Context

Fases 1 y 2 dejaron la capa de datos/estado de productos completa y reactiva: `ProductRepository` (`insert`, `update`, `disable`, `enable`, `watchAll`) con señal de cambio compartida por instancia de base, y `productProvider` (`StreamProvider<List<Product>>`) que re-emite ante cualquier mutación. Ver proposal.md — Why para la motivación. `main.dart` es "Hello World" envuelto en `ProviderScope`; `go_router ^14.8.1` e `intl ^0.20.2` están declarados pero sin uso.

## Goals / Non-Goals

**Goals:**
- Primera pantalla real de negocio: listado de productos (nombre, precio, tienda), formulario de alta/edición con validación y borrado por swipe con confirmación.
- Navegación con `go_router` cableada desde `main.dart`, con rutas que la fase de Listas pueda extender sin reestructurar la raíz.
- Mutaciones disparadas desde la UI que refresquen `productProvider` automáticamente vía la señal de cambio ya existente.
- Tests de widgets para cada pantalla con DB en memoria.

**Non-Goals:**
- Shell de navegación inferior (Productos | Listas) — entra en la fase de UI de listas.
- Restauración/rehabilitación de productos ocultos (`enable()` queda sin pantalla en esta fase).
- Gestión de listas de compra ni costos totales (fases posteriores).
- Autocompletado/sugerencias de tienda (campo libre por ahora).

## Decisions

### 1. `go_router` con rutas planas de producto, sin shell inferior
`main.dart` pasa a `MaterialApp.router` con un `GoRouter`:

```
/productos            -> ProductosScreen        (home)
/productos/nuevo      -> ProductoFormScreen     (alta)
/productos/:id/editar -> ProductoFormScreen     (edición, precargado)
```

- La raíz es la lista de productos (fase actual). Cuando llegue la UI de listas, basta agregar `/listas` y, si se quiere, un `StatefulShellRoute` con bottom nav sin tocar las rutas de producto.
- Alternativas descartadas: `Navigator.push` directo (desperdicia `go_router` ya declarado y obligaría a reescribir `main.dart` en la fase de listas); `showModalBottomSheet` para el formulario (una página completa es más testeable y escala mejor cuando el formulario crezca con cantidad/sugerencias).

### 2. Formulario como pantalla completa con `Form` + validación en español
`ProductoFormScreen` reutilizable para alta y edición: en modo edición recibe el `Product` (vía `extra` o por id) y precarga los campos.

- Validación: nombre y tienda obligatorios (no vacíos, sin whitespace); precio unitario > 0, parseado con separador decimal según locale (es_ES acepta coma), re-formateado con `intl` al guardar/visualizar (`$1.234,56`).
- Guardado: alta -> `repo.insert`, edición -> `repo.update` (que preserva `activo`, según spec de fase 1). Tras guardar, `context.pop()`. La señal de cambio del repositorio refresca el listado solo.
- Decisión no tomada en esta fase: precio con ceros / límite de decimales / valor 0 — QA se resuelve con `precio > 0` y ninguna regla adicional.

### 3. Borrado = borrado suave (`disable`) con confirmación honesta
Swipe (`Dismissible`) sobre la fila abre un `AlertDialog` de confirmación:

- Texto explícito: "Desaparecerá de la lista de productos" (no "se eliminará"), alineado con la spec de fase 1 («deshabilitar, no eliminar físicamente; listas existentes conservan nombre y precio»).
- Confirmar -> `repo.disable(id)`. La señal compartida re-emite `productProvider` y la fila sale del listado al reactivarse el estado.
- No se agrega `delete()` físico al repositorio: contradiría la spec de productos y rompería las FK de `shopping_list_items`.
- No hay vía de `enable()` en esta fase (Non-Goal).

### 4. Mutaciones desde la UI vía repositorio, no providers de acción nuevos
Los widgets obtienen la DB con `ref.read(databaseProvider.future)` y construyen un `ProductRepository` al momento de la mutación. Como la señal de cambio se comparte por identidad de base (`Expando`), `productProvider` (que construye su propio repositorio) re-emite al instante.

- Alternativa descartada: `NotifierProvider` de acción que centralice inserts/updates — añade una capa sin beneficio real a esta escala, dado que la reactividad ya está resuelta por el stream. Si en fases futuras se necesitan side-effects (ej. toasts de undo, batch), se introduce ahí sin cambiar la UI.
- Rendimiento: re-query completo del catálogo por mutación; aceptado, es local y de un solo usuario (misma decisión que fase 2).

### 5. Estructura de archivos en `lib/ui/`
```
lib/
  router.dart                        -> GoRouter con rutas de producto
  ui/productos/productos_screen.dart
  ui/productos/producto_form_screen.dart
  ui/productos/widgets/  (filas de lista, diálogo de confirmación)
```
Los nombres de pantalla y rutas en español, siguiendo las convenciones del proyecto. La UI observa `productProvider` con `ref.watch` y maneja los estados `AsyncValue` (loading / data / error).

### 6. Test de widgets con DB en memoria y overrides
Helpers nuevos en `test/helpers/`: `pumpApp` (o equivalente) que monta `ProductosScreen`/`ProductoFormScreen` dentro de un `ProviderScope` con `databaseProvider` overrideado a la DB en memoria (`openInMemoryDatabase`). Cada pantalla lleva widget tests: lista pinta nombre/precio/tienda, swipe abre diálogo, confirmar elimina la fila, formulario valida y persiste, edición precarga.

## Risks / Trade-offs

- [Warnings de la rule de `tasks` en `openspec/config.yaml` («Rules for 'tasks' must be an array of strings»)] → Coexiste con los cambios previos; no bloquea `openspec validate`. Se puede corregir en la config aparte, sin tocar este cambio.
- [Swipe-dismiss sin `confirmDismiss` correcto puede ocultar la fila antes de confirmar] → `Dismissible` usa `confirmDismiss` para abrir el diálogo y cancelar si se rechaza; la fila solo se desliza tras el OK efectivo (el estado se refresca solo).
- [Formato decimal es_ES con coma puede fallar al parsear en locales/repos distintos] → El parseo se hace explícito (acepta coma y punto) y el guardado normaliza a `double`; no depende del locale del dispositivo.
- [`go_router` requiere `build`/`context` que hoy no existen en `main.dart`] → Cambio acotado a `main.dart` + `router.dart` nuevo; el resto de la app no se toca.

## Migration Plan

- Sin cambios de esquema ni migración DB; no hay estado persistido que migrar.
- Navegación: `main.dart` pasa de `MaterialApp` a `MaterialApp.router`; los tests de providers existentes no dependen de widgets, así que no se ven afectados.
- Rollback: revertir el commit; la app vuelve al `MaterialApp` actual sin pérdida de datos.

## Open Questions

- Formato exacto del diálogo de confirmación y mensajes de validación: se definen con copy de UI en la implementación, sin alterar specs ni enfoque.
- Publicar precio con moneda "$" fija o símbolo local: resuelto por la convención del proyecto (intl es_ES, `$1.234,56`); no requiere decisión adicional.