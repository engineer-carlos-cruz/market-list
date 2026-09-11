## Context

Fase 1 dejó: `AppDatabase` (singleton, 3 tablas v1, `PRAGMA foreign_keys = ON`), modelo `Product` inmutable y `ProductRepository` con patrón reactivo broadcast + re-query (`watchAll()`). Verificado en fase 1: sqflite no ofrece streams, de ahí el `StreamController` manual. `flutter_riverpod 2.6.1` y `sqflite_common_ffi` (dev) ya están declarados en `pubspec.yaml`. `main.dart` sigue siendo el esqueleto "Hello World". Ver proposal.md — Why para la motivación.

## Goals / Non-Goals

**Goals:**
- Providers reactivos en `lib/state/providers/`: uno por entidad (`productProvider`, `shoppingListProvider`, `shoppingListItemProvider`) más `databaseProvider` de infraestructura.
- Modelos y repositorio de listas que cubran las tablas `shopping_lists` y `shopping_list_items` ya existentes.
- `main.dart` envuelto en `ProviderScope` (sin UI nueva).
- Tests del repositorio de listas en memoria y tests de providers con `ProviderContainer` + DB en memoria.

**Non-Goals:**
- Pantallas, formularios o navegación (fase 3).
- Costo total de lista (`sum(cantidad * precio_unitario)`) — se deriva en la fase de UI.
- Borrado físico ni política de borrado de listas/cascada (fase futura).
- Providers `family` por id de lista (el filtrado se hace en la UI).

## Decisions

### 1. `FutureProvider` para la DB + `StreamProvider` por entidad
`databaseProvider` es un `FutureProvider<Database>` que resuelve `AppDatabase.instance.database` (la apertura es asíncrona y ya queda cacheada por el singleton). Cada entidad expone un `StreamProvider<List<T>>` que espera `ref.watch(databaseProvider.future)`, construye su repositorio y delega en `watchAll()`/`watchAllItems()`.
- Alternativas: `Provider<Future<Database>>` (obliga a combinar con `.then` en el consumidor; peor ergonomía y sin estado de carga en `AsyncValue`), repos construidos en un `Provider<Repository>` (choca con la apertura asíncrona; innecesario a esta escala).

```
                 +---------------------+
                 | databaseProvider    |
                 | FutureProvider<DB>  +--> AppDatabase.instance.database
                 +----------+----------+
                            |
        +-------------------+-------------------+
        v                   v                   v
+-----------------+ +-----------------+ +----------------------+
| productProvider | | shoppingList   | | shoppingListItem      |
| StreamProvider  | | Provider       | | Provider              |
| List<Product>   | | List<ShoppingL | | List<ShoppingListItem>|
+-----------------+ +----------------+ +----------------------+
        |                    |                    |
        v                    v                    v
   (UI fase 3 observa con ref.watch -> refresco automático)
```

### 2. Un solo repositorio para listas e ítems
`ShoppingListRepository(db)` trata lista + ítems como un agregado: `insert(ShoppingList) -> int` (`lastInsertId`), `insertItem(ShoppingListItem) -> int`, `watchAll()` (listas) y `watchAllItems()` (todos los ítems). Un único `StreamController<void>.broadcast()` compartido: cualquier mutación re-emite ambos streams.
- Alternativa: repos separados por entidad (descartada: ítems sin su lista no tienen dominio propio; mantener dos controladores duplica lógica sin beneficio).
- Orden: listas por `fecha DESC` (las recientes primero); ítems por `id` (orden de inserción).
- Sobre-consulta aceptada: una mutación de ítem re-emite también las listas; trivial para uso local de un solo usuario.

### 3. `fecha` como `DateTime` en el modelo
La columna `fecha` es `TEXT` y se persiste en ISO-8601; el modelo expone `DateTime` y `fromMap`/`toMap` parsean/serializan. `intl` formateará en la UI (fase 3). Alternativa: `String` crudo (descartada: la UI necesitaría parsear igualmente y el dominio pierde tipado).

### 4. `main.dart` solo con `ProviderScope`
`runApp(ProviderScope(child: MainApp()))`. El `MaterialApp` conserva su contenido actual; no hay pantallas de negocio todavía. Cumple el requisito "Inicialización de la capa de estado" del delta de `state`.

### 5. Repositorio construido dentro del provider
Cada `StreamProvider` crea su repositorio con la DB resuelta. Cambiar la DB (solo ocurre al reabrir) reinicia los providers; los tests pueden `overrideWith` `databaseProvider` con una DB en memoria (`sqflite_common_ffi`), lo que hace la capa de estado testeable sin singletons.

## Risks / Trade-offs

- [Un único `StreamController` re-emite ambos streams ante cualquier mutación] → Aceptado: sobre-consulta trivial, local y de un solo usuario; simplifica el código.
- [`StreamProvider` recrea el repositorio si la DB cambia] → Solo ocurre al reabrir la base; sin impacto práctico en una app local de un usuario.
- [`shoppingListItemProvider` emite todos los ítems de todas las listas] → El filtrado por lista se hace en la UI (fase 3) o con un `family` posterior, sin tocar esquema ni provider actuales.
- [Sin límite de tamaño de stream en memoria] → Escala suficiente para listas de mercado personales; de crecer, se agrega paginación sin cambiar el contrato del provider.

## Migration Plan

- Sin cambios de esquema: las tablas ya existen desde v1; no hay migración en esta fase.
- Despliegue: solo se agregan archivos nuevos y se envuelve `main.dart`; no hay estado persistido que migrar.
- Rollback: revertir el commit; la DB queda intacta.

## Open Questions

- Costo total por lista (`sum(cantidad * precio_unitario)`): se resuelve en la fase de UI como dato derivado; no requiere nuevo provider ni cambio a este diseño.
- Nada más pendiente: las demás decisiones (families, filtrado por lista, orden) son de la fase de UI y no alteran specs, enfoque ni tareas.