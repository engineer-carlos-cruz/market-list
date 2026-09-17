## ADDED Requirements

### Requirement: Actualización de cantidad de un ítem
El sistema SHALL permitir modificar la cantidad de un ítem existente conservando su id y sus referencias a lista y producto, y SHALL rechazar cantidades no positivas. Toda actualización SHALL re-emitir los streams de listas y de ítems.

#### Scenario: Actualizar la cantidad de un ítem
- **WHEN** se actualiza la cantidad de un ítem a un valor positivo
- **THEN** el valor queda persistido conservando el id del ítem y sus referencias, y los streams de listas e ítems emiten el estado actualizado

#### Scenario: Cantidad inválida
- **WHEN** se intenta actualizar la cantidad de un ítem a cero o a un valor negativo
- **THEN** la operación falla y la cantidad anterior se conserva

### Requirement: Eliminación de ítems de una lista
El sistema SHALL permitir eliminar un ítem de una lista sin modificar la lista ni el producto referenciado, y SHALL re-emitir los streams de listas y de ítems tras la eliminación.

#### Scenario: Eliminar un ítem
- **WHEN** se elimina un ítem de una lista
- **THEN** el ítem desaparece de los streams de ítems, mientras la lista y el producto se conservan

### Requirement: Bloqueo de ítems duplicados en una lista
El sistema SHALL impedir que un mismo producto esté presente más de una vez en la misma lista: agregar un producto ya incluido SHALL fallar sin crear una fila nueva.

#### Scenario: Intentar duplicar un producto en la lista
- **WHEN** se intenta insertar un ítem cuyo id_producto ya existe en la misma lista
- **THEN** la operación falla y no se crea una fila duplicada

### Requirement: Stream de detalle de una lista con productos
El sistema SHALL exponer un stream que emite las líneas de una lista concreta, cada línea compuesta por el ítem y el producto referenciado con su nombre y precio, incluyendo productos deshabilitados, ordenadas por nombre de producto. El stream SHALL re-emitir cuando cambian los ítems de la lista o cuando cambia cualquier producto del catálogo, de modo que el detalle y el total reflejen los precios vigentes.

#### Scenario: Suscripción inicial al detalle de una lista
- **WHEN** un consumidor se suscribe al detalle de una lista
- **THEN** recibe una emisión con sus líneas, cada una con nombre y precio del producto, ordenadas por nombre

#### Scenario: La lista incluye productos deshabilitados
- **WHEN** una lista contiene ítems de productos que fueron deshabilitados
- **THEN** el stream de detalle sigue emitiendo esas líneas con su nombre y precio

#### Scenario: El detalle se refresca ante mutaciones de ítem
- **WHEN** se actualiza la cantidad o se elimina un ítem de la lista
- **THEN** el stream de detalle emite un estado actualizado

#### Scenario: El detalle se refresca ante cambios de producto
- **WHEN** se crea, modifica o deshabilita un producto del catálogo
- **THEN** el stream de detalle emite un estado actualizado con los datos vigentes del producto

### Requirement: Derivación de tiendas del catálogo
El sistema SHALL exponer las tiendas distintas presentes en el catálogo de productos, ordenadas alfabéticamente y sin duplicados, y SHALL re-emitir la lista cuando cambie el catálogo.

#### Scenario: Obtener tiendas existentes
- **WHEN** un consumidor consulta las tiendas disponibles
- **THEN** recibe la lista de tiendas distintas presentes en el catálogo, ordenadas alfabéticamente y sin repetidos

#### Scenario: La lista de tiendas se refresca con el catálogo
- **WHEN** se agrega un producto con una tienda nueva o se modifica la tienda de un producto existente
- **THEN** la lista de tiendas se re-emite incluyendo el cambio