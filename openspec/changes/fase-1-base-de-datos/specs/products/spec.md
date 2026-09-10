## Purpose

Catálogo local de productos de mercado con persistencia en SQLite, borrado suave y listado reactivo ordenado por nombre, listo para alimentar pantallas vía Riverpod.

## ADDED Requirements

### Requirement: Persistencia local de productos
El sistema SHALL almacenar los productos en una base de datos SQLite local, versionada (versión 1), sin ningún tipo de comunicación de red. El esquema SHALL quedar preparado para migraciones futuras de manera que un cambio de versión preserve los datos existentes.

#### Scenario: La base de datos se crea localmente
- **WHEN** la aplicación inicia la capa de datos por primera vez
- **THEN** se crea una base de datos SQLite local con los esquemas de productos, listas de compra y sus ítems, reportando versión 1

#### Scenario: Un upgrade de esquema preserva los datos
- **WHEN** el esquema de base de datos evoluciona a una versión superior
- **THEN** la migración se ejecuta preservando los registros existentes

### Requirement: Registro de productos
El sistema SHALL permitir registrar un producto con nombre obligatorio, precio unitario y tienda. Cada producto recibe un id único y queda habilitado por defecto. Una operación de registro SHALL devolver el id asignado.

#### Scenario: Registrar un producto nuevo
- **WHEN** se registra "Leche en bolsa x 900 ml" con precio unitario y tienda
- **THEN** el producto queda persistido con un id único, sus datos intactos y estado habilitado, y la operación devuelve su id

#### Scenario: Registro sin nombre
- **WHEN** se intenta registrar un producto sin nombre
- **THEN** la operación falla y el producto no queda persistido

### Requirement: Actualización de productos
El sistema SHALL permitir modificar el nombre, el precio unitario y la tienda de un producto existente. La actualización NO SHALL modificar el estado de habilitación del producto.

#### Scenario: Modificar los datos de un producto
- **WHEN** se actualiza el precio de un producto existente
- **THEN** los nuevos datos quedan persistidos y el producto conserva su id y su estado de habilitación

### Requirement: Borrado suave de productos
El sistema SHALL deshabilitar un producto sin eliminarlo físicamente. Un producto deshabilitado NO SHALL aparecer en los listados de productos activos y NO SHALL poder incorporarse a listas de compra nuevas; las listas de compra existentes que lo referencian SHALL seguir mostrando su nombre y su precio.

#### Scenario: Deshabilitar un producto
- **WHEN** se deshabilita un producto activo
- **THEN** el producto deja de aparecer en el listado de productos activos, pero su registro permanece en la base de datos

#### Scenario: Rehabilitar un producto
- **WHEN** se habilita un producto previamente deshabilitado
- **THEN** el producto vuelve a aparecer en el listado de productos activos conservando sus datos

#### Scenario: Las listas existentes conservan productos deshabilitados
- **WHEN** una lista de compra contiene un producto que posteriormente se deshabilita
- **THEN** la lista sigue mostrando el producto y su precio sin cambios

### Requirement: Listado reactivo de productos activos
El sistema SHALL exponer un stream que emite la lista de productos activos, ordenada por nombre sin distinguir mayúsculas ni minúsculas, y SHALL emitir una nueva lista tras cada registro, actualización, deshabilitación o habilitación.

#### Scenario: Suscripción inicial
- **WHEN** un consumidor se suscribe al listado de productos
- **THEN** recibe una emisión con todos los productos activos ordenados por nombre, sin distinguir mayúsculas de minúsculas

#### Scenario: El listado se refresca tras una mutación
- **WHEN** se registra un producto nuevo
- **THEN** el stream emite una lista actualizada que incluye al nuevo producto en su posición ordenada

#### Scenario: El listado excluye productos deshabilitados
- **WHEN** se deshabilita un producto que estaba activo
- **THEN** el stream emite una lista actualizada en la que ese producto ya no aparece