## Purpose

Dominio de listas de compra: modelos `ShoppingList`/`ShoppingListItem` sobre las tablas del esquema v1 y repositorio con streams reactivos que alimentan la capa de estado.

## ADDED Requirements

### Requirement: Modelo y persistencia de listas de compra
El sistema SHALL representar una lista de compra con tienda y fecha, y sus ítems con producto y cantidad, persistidos en las tablas `shopping_lists` y `shopping_list_items` existentes del esquema v1, sin cambios de esquema ni migraciones.

#### Scenario: Crear una lista y agregarle ítems
- **WHEN** se crea una lista de compra con tienda y fecha
- **THEN** la lista queda persistida con un id único y se le pueden agregar ítems que referencian un producto existente y una cantidad positiva

### Requirement: Stream reactivo de listas de compra
El sistema SHALL exponer un stream que emite todas las listas de compra existentes y SHALL emitir una nueva lista tras cada alta de lista o de ítem.

#### Scenario: Suscripción inicial a las listas
- **WHEN** un consumidor se suscribe al listado de listas de compra
- **THEN** recibe una emisión con todas las listas de compra existentes

#### Scenario: El listado de listas se refresca tras una mutación
- **WHEN** se crea una lista de compra nueva
- **THEN** el stream emite una lista actualizada que incluye la nueva lista

### Requirement: Stream reactivo de ítems de listas
El sistema SHALL exponer un stream que emite todos los ítems de todas las listas y SHALL emitir una nueva lista tras cada alta de ítem.

#### Scenario: Suscripción inicial con ítems
- **WHEN** un consumidor se suscribe al listado de ítems
- **THEN** recibe una emisión con todos los ítems existentes de todas las listas

#### Scenario: El listado de ítems se refresca tras una mutación
- **WHEN** se agrega un ítem a una lista existente
- **THEN** el stream emite una lista actualizada que incluye el nuevo ítem