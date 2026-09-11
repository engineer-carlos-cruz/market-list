## Purpose

Capa de estado Riverpod: providers reactivos que exponen la base de datos local y los listados de productos, listas de compra e ítems, refrescándose automáticamente ante cualquier mutación de la base.

## ADDED Requirements

### Requirement: Provider de base de datos
El sistema SHALL exponer un provider Riverpod que provea la base de datos SQLite local y SHALL entregarla lista tras su apertura inicial, sin iniciar ninguna comunicación de red.

#### Scenario: Consumir la base desde un provider
- **WHEN** un consumidor lee el provider de base de datos
- **THEN** recibe la instancia única de la base local ya abierta

### Requirement: Stream reactivo de productos
El sistema SHALL exponer un provider Riverpod de stream que emite los productos activos según el listado reactivo del repositorio y SHALL re-emitir la lista actualizada tras cada mutación de la tabla `products`.

#### Scenario: La capa de estado reacciona a cambios de productos
- **WHEN** se registra, modifica o deshabilita un producto
- **THEN** el provider de productos emite la lista actualizada sin intervención manual
- **AND** los widgets que observan el provider se refrescan solos

### Requirement: Streams reactivos de listas y ítems
El sistema SHALL exponer providers Riverpod de stream para las listas de compra y sus ítems, y SHALL re-emitir las listas actualizadas tras cada mutación de las tablas `shopping_lists` o `shopping_list_items`.

#### Scenario: La capa de estado reacciona a cambios de listas
- **WHEN** se crea una lista o se agrega un ítem
- **THEN** los providers de listas e ítems emiten las listas actualizadas y los widgets que los observan se refrescan solos

### Requirement: Inicialización de la capa de estado
El sistema SHALL inicializar la capa de estado al arrancar la aplicación, envolviendo la app en un `ProviderScope` raíz, para que los providers estén disponibles desde el inicio.

#### Scenario: Arranque de la aplicación
- **WHEN** la aplicación inicia
- **THEN** la capa de estado queda disponible bajo un `ProviderScope` raíz