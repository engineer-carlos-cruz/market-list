## Purpose

Gestión de listas de compra: pantalla de listado con tienda y fecha, creación de listas seleccionando tienda, detalle con productos y cantidades editables, y total en vivo formateado como moneda.

## ADDED Requirements

### Requirement: Listado de listas de compra
El sistema SHALL exponer una pantalla Listas que muestra las listas de compra guardadas ordenadas por fecha descendente, indicando en cada una su tienda y su fecha formateada en español, y SHALL dejar accesibles Productos y Listas desde una navegación inferior persistente.

#### Scenario: Ver el listado de listas
- **WHEN** el usuario navega a la pestaña Listas
- **THEN** ve las listas guardadas con su tienda y fecha, las más recientes primero

#### Scenario: Sin listas guardadas
- **WHEN** no existe ninguna lista de compra
- **THEN** la pantalla muestra un estado vacío que invita a crear la primera lista

#### Scenario: Abrir el detalle de una lista
- **WHEN** el usuario toca una lista del listado
- **THEN** navega al detalle de esa lista mostrando su tienda y fecha

### Requirement: Creación de lista con selección de tienda
El sistema SHALL permitir crear una lista de compra eligiendo una tienda entre las existentes derivadas del catálogo de productos o ingresando una tienda nueva. La fecha SHALL fijarse al momento de la creación y la lista resultante SHALL aparecer en el listado.

#### Scenario: Crear una lista con una tienda del catálogo
- **WHEN** el usuario inicia la creación de una lista y elige una tienda existente derivada del catálogo
- **THEN** la lista queda creada con esa tienda y la fecha actual, y aparece en el listado

#### Scenario: Crear una lista con una tienda nueva
- **WHEN** el usuario inicia la creación de una lista e ingresa una tienda que no está en el catálogo
- **THEN** la lista queda creada con esa tienda y la fecha actual, y aparece en el listado

#### Scenario: Creación sin tienda
- **WHEN** el usuario intenta crear una lista sin indicar tienda
- **THEN** la acción no se confirma y la lista no se crea

### Requirement: Detalle de lista con productos y cantidades
El sistema SHALL mostrar el detalle de una lista con su tienda y fecha en el encabezado y con sus líneas (nombre del producto, precio unitario y cantidad), SHALL permitir ajustar la cantidad de cada línea mediante un stepper y SHALL permitir agregar productos activos del catálogo sin crear duplicados.

#### Scenario: Agregar un producto a la lista
- **WHEN** el usuario agrega un producto activo del catálogo a la lista
- **THEN** una nueva línea aparece con ese producto, su precio unitario y cantidad 1

#### Scenario: Bloqueo de productos duplicados
- **WHEN** el usuario intenta agregar un producto que ya está en la lista
- **THEN** no se agrega una línea duplicada

#### Scenario: Incrementar y disminuir la cantidad
- **WHEN** el usuario toca `+` o `-` en una línea
- **THEN** la cantidad se incrementa o disminuye en 1 dentro del rango permitido y el cambio queda persistido

#### Scenario: Un producto deshabilitado sigue visible
- **WHEN** una lista contiene un producto que luego se deshabilita
- **THEN** la lista sigue mostrando su nombre y su precio en la línea

### Requirement: Borrado de ítems desde el stepper
El sistema SHALL eliminar un ítem de la lista cuando el usuario confirma el borrado, y SHALL solicitar confirmación cuando se intenta decrementar una línea cuya cantidad es 1.

#### Scenario: Decrementar en cantidad 1 solicita confirmación
- **WHEN** el usuario toca `-` en una línea con cantidad 1
- **THEN** se muestra un diálogo de confirmación de borrado del ítem

#### Scenario: Confirmar el borrado elimina el ítem
- **WHEN** el usuario confirma el borrado de un ítem
- **THEN** la línea desaparece de la lista y el total se actualiza

#### Scenario: Cancelar el borrado lo descarta
- **WHEN** el usuario cancela el diálogo de confirmación
- **THEN** el ítem se conserva con su cantidad

### Requirement: Total de la lista en vivo
El sistema SHALL mostrar en la pantalla de detalle el costo total de la lista, calculado como la suma de `cantidad * precio_unitario` sobre todas sus líneas, SHALL actualizarlo ante cualquier cambio de cantidad, alta o borrado, y SHALL formatearlo como moneda con `intl` es_ES.

#### Scenario: Total inicial con el precio vigente
- **WHEN** el usuario abre el detalle de una lista con líneas
- **THEN** el total muestra la suma de `cantidad * precio_unitario` usando los precios vigentes de cada producto

#### Scenario: El total responde a cambios de cantidad
- **WHEN** el usuario incrementa o decrementa la cantidad de una línea
- **THEN** el total se recalcula y se muestra actualizado al instante

#### Scenario: El total responde a altas y borrados
- **WHEN** el usuario agrega o elimina una línea
- **THEN** el total se recalcula y se muestra actualizado al instante

#### Scenario: Formato de moneda
- **WHEN** el total se muestra en pantalla
- **THEN** usa el formato de moneda es_ES (ej. `$1.234,56`)