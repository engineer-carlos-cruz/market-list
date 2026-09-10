## Why

La app es un esqueleto (`main.dart` sin contenido) sin capa de datos. Esta fase construye la fundación sobre la que vivirán todas las pantallas: el esquema SQLite local (v1) y el repositorio de productos con reactividad lista para Riverpod. Sin esto no hay Productos, Listas ni cálculo de costos.

## What Changes

- Crear `lib/data/database/app_database.dart`: singleton SQLite (sqflite) con DB `market_list.db`, versión 1, `PRAGMA foreign_keys = ON` y `onUpgrade` estructurado (switch por versión) para migraciones futuras.
- Crear las 3 tablas del esquema v1:
  - `products` (id, nombre, precio_unitario, tienda, activo DEFAULT 1)
  - `shopping_lists` (id, tienda, fecha)
  - `shopping_list_items` (id, id_lista FK, id_producto FK, cantidad INTEGER)
- Crear el modelo `Product` con `fromMap`/`toMap` (indispensable para que el repositorio tipifique sus resultados).
- Crear `lib/data/repositories/product_repository.dart` con CRUD:
  - `insert`, `update`, `disable`/`enable` (borrado suave, no físico) y `watchAll`.
  - `watchAll` expone `Stream<List<Product>>` con **solo productos activos**, ordenados por `nombre COLLATE NOCASE`; debe construirse manualmente porque sqflite no ofrece streams.
- `main.dart` permanece intacto (fase de solo-datos).

## Capabilities

### New Capabilities
- `products`: catálogo local de productos — persistencia (schema + repositorio), borrado suave y consulta reactiva ordenada por nombre.

### Modified Capabilities
- Ninguna (no existen specs previas aún).

## Impact

- **Nuevos archivos**: `lib/data/database/app_database.dart`, `lib/data/models/product.dart`, `lib/data/repositories/product_repository.dart`.
- **Dependencias**: ninguna nueva en runtime (sqflite y path ya están). Opcional: `sqflite_common_ffi` como dev_dependency para tests del repositorio en memoria.
- **Esquema**: versionado en SQLite (v1). Futuras fases que agreguen columnas/tablas usarán `onUpgrade` con migración explícita por versión.
- **Sin red**: todo el almacenamiento es local.