## Context

La app es un esqueleto Flutter sin capa de datos (ver proposal.md — Why). Esta fase introduce la base SQLite local (v1) y el repositorio de productos. Restricciones vigentes: 100% local sin red, tablas SQL en snake_case, modelos Dart en camelCase, sin librerías visuales extra; sqflite 2.4.3, path 1.9.1 y flutter_riverpod 2.6.1 ya declarados en `pubspec.yaml`. Verificado en `sqflite_common-2.5.11`: sqflite **no** expone streams/`watch`, por lo que la reactividad hay que construirla.

## Goals / Non-Goals

**Goals:**
- Esquema SQLite v1 de las 3 tablas con `onUpgrade` ya encadenado para migraciones futuras.
- Repositorio de productos con CRUD, borrado suave (`activo`) y listado reactivo ordenado por nombre.
- Dejar la capa lista para Riverpod (`Stream<List<Product>>`).
- Tests del repositorio con `sqflite_common_ffi` en memoria.

**Non-Goals:**
- Repositorios de `ShoppingList` / `ShoppingListItem` (fases posteriores).
- Cualquier UI, navegación o provider Riverpod.
- Re-habilitación desde la UI (habilitar/deshabilitar es API del repositorio; la pantalla es otra fase).
- Ordenación natural con acentos.

## Decisions

### 1. Singleton `AppDatabase` + repositorio por entidad
Un `AppDatabase` abre la base una sola vez y expone `Database`; `ProductRepository` recibe la base (o el singleton) y opera sobre la tabla `products`.
- Alternativas: usar `openDatabase` por llamada (descartada: reabrir en cada repo es frágil y lento), drift o sqflite's `databaseFactory` global (drift = dependencia nueva grande; sin motivo).
- Forma: `lib/data/database/app_database.dart`, `lib/data/repositories/product_repository.dart`, `lib/data/models/product.dart` — capas: datos (sqflite) / estado (riverpod) / UI, según convención del config.

### 2. Esquema v1 + migraciones encadenadas
Versión = 1; `onConfigure` activa `PRAGMA foreign_keys = ON`. `_onCreate` ejecuta el DDL completo; `onUpgrade` usa un `switch` por versión de forma que cada futura versión agregue su bloque sin reescribir migraciones anteriores.

```
products              shopping_lists        shopping_list_items
+-------------------+ +------------------+ +------------------+
| id  INTEGER PK AI | | id   INTEGER PK  | | id  INTEGER PK   |
| nombre TEXT NN    | | tienda TEXT      | | id_lista    FK → shopping_lists(id)
| precio_unitario   | | fecha  TEXT ISO  | | id_producto FK → products(id)
| tienda TEXT       | +------------------+ | cantidad INTEGER NN
| activo INT NN D=1 |                      +------------------+
+-------------------+
```

### 3. Borrado suave con columna `activo` (0/1), sin `delete` físico
`disable(id)` / `enable(id)` = `UPDATE products SET activo = ?`. El registro nunca se borra; los ítems de listas existentes siguen resolviendo nombre y precio. Como la fila persiste, no se necesita `ON DELETE CASCADE`/`RESTRICT` para `id_producto`.
- Alternativa: `deleted_at` (timestamp NULL = activo). Descartada: no se requiere historial, y `activo` refleja el concepto del dominio ("se deshabilita").
- El `id_lista` queda sin comportamiento de borrado en cascada a propósito: borrar listas es una fase futura que definirá su política.

### 4. `cantidad` INTEGER (unidades enteras)
La unidad de medida se embebe en el nombre ("Leche en bolsa x 900 ml"), por lo que la cantidad del ítem solo necesita unidades. El costo (`sum(cantidad * precio_unitario)`) se calcula como `REAL` para la moneda con intl.

### 5. Reactividad manual con `StreamController` + re-query
sqflite no ofrece streams, así que el repositorio mantiene un `StreamController<void>.broadcast()` interno; cada mutación (insert/update/disable/enable) hace su operación DML y luego emite la señal. `watchAll()` inicia con una consulta y después re-emite ante cada cambio, siempre leyendo el estado actual de la tabla. Filtro `WHERE activo = 1` y `ORDER BY nombre COLLATE NOCASE`.
- Alternativas: rxdart `startWith` (dependencia extra, descartada), `StreamProvider` consultando a demanda (descartada: el repositorio debe ser la fuente de verdad).
- Una futura pantalla de "re-habilitar" puede pedir listar inactivos con un parámetro, sin tocar el esquema.

```
UI → StreamProvider(List<Product>) ──┐
                                     ▼
                  repo.watchAll(): Stream<List<Product>>
                                     │  async*: yield queryActivos(); await señal;
                                     ▲
   insert/update/disable/enable ─────┘  (broadcast → re-query estado actual)
```

### 6. Modelo `Product` inmutable
`id, nombre, precio_unitario, tienda, activo`, con `fromMap`/`toMap` (claves snake_case de la tabla). `insert` devuelve `int id` (lastInsertId).

### 7. Tests del repositorio en memoria
`sqflite_common_ffi` como `dev_dependency` (paquete local, sin red) con `databaseFactoryFfi` + `inMemoryDatabasePath`, cubriendo insert/update/disable/enable/watchAll (orden, filtro de activos, refresco tras mutación). Verificación con `flutter analyze` y `flutter test`.

## Risks / Trade-offs

- [Raza en el stream manual si una mutación ocurre durante un re-query] → Mitigación: la señal broadcast dispara un re-query que siempre lee el estado actual de la tabla; riesgo de desorden transitorio nulo para consumo local de un solo usuario.
- [`COLLATE NOCASE` no ordena acentos ("Águila" tras "Zanahoria")] → Mitigación: aceptado; mitigación futura (columna normalizada) sin cambiar esquema de comportamiento.
- [`PRAGMA foreign_keys = ON` hará fallar un borrado de lista con ítems] → No aplica a esta fase (no existe repositorio de listas); la fase de listas define su política (probablemente CASCADE explícito).
- [Rules de `tasks` en `openspec/config.yaml` mal formados (el `: ` hace que YAML lo parsee como mapa) y openspec los ignora] → No bloquea el diseño; corrección opcional de config fuera de este change.

## Migration Plan

- Despliegue: sin rollback necesario; es la primera versión. Procedimiento para futuras fases: subir `version` en 1 y agregar el bloque de migración en `onUpgrade` (patrón switch ya encadenado).
- Rollback: N/A (solo local; recrear la base borrando el archivo en entornos dev).

## Open Questions

- ¿Una futura pantalla deberá permitir re-habilitar productos viendo los inactivos? Se resuelve en la fase de UI; el repositorio ya lo soporta con un listado `includeInactive` sin afectar este esquema ni tasks.
- Nada más pendiente: las decisiones restantes afectarían specs o tareas y fueron resueltas en exploración (cantidad INTEGER, NOCASE, borrado suave con `activo`, modelo en esta fase).