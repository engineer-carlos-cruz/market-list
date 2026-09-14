## Purpose

Gestión de productos desde la interfaz de usuario: listado de productos activos con su nombre, precio unitario y tienda; alta y edición mediante un formulario validado; y borrado por deslizamiento con confirmación. La UI refleja automáticamente los cambios persistidos en la base local.

## ADDED Requirements

### Requirement: Listado de productos activos
El sistema SHALL mostrar en una pantalla "Productos" la lista de productos activos, cada uno con su nombre, su precio unitario formateado como moneda y su tienda, ordenados por nombre sin distinguir mayúsculas ni minúsculas. El listado SHALL refrescarse automáticamente tras cualquier alta, edición o borrado, sin interacción del usuario.

#### Scenario: La pantalla muestra los productos activos
- **WHEN** el usuario abre la pantalla "Productos" y existen productos activos
- **THEN** se muestran todos los productos activos ordenados por nombre, cada uno con su precio unitario formateado y su tienda

#### Scenario: La pantalla refleja una alta reciente
- **WHEN** el usuario registra un producto nuevo
- **THEN** el listado se actualiza solo e incluye el producto nuevo en su posición correcta

#### Scenario: No hay productos
- **WHEN** no existe ningún producto activo
- **THEN** la pantalla muestra un mensaje indicando que aún no hay productos y una invitación a crear uno

### Requirement: Alta de producto con formulario validado
El sistema SHALL permitir registrar un producto mediante un formulario con los campos nombre, precio unitario y tienda. El formulario SHALL validar que el nombre y la tienda no estén vacíos y que el precio unitario sea mayor que cero, mostrando mensajes de error en español. Un registro válido SHALL persistir el producto y devolver el usuario al listado, que refleja el producto nuevo.

#### Scenario: Registro válido
- **WHEN** el usuario completa los campos con un nombre, un precio unitario mayor que cero y una tienda, y confirma el guardado
- **THEN** el producto queda registrado y el usuario vuelve al listado, que ya lo muestra

#### Scenario: Nombre vacío
- **WHEN** el usuario confirma el guardado con el campo nombre vacío
- **THEN** el formulario marca un error de nombre obligatorio y no persiste el producto

#### Scenario: Tienda vacía
- **WHEN** el usuario confirma el guardado con el campo tienda vacío
- **THEN** el formulario marca un error de tienda obligatoria y no persiste el producto

#### Scenario: Precio no mayor que cero
- **WHEN** el usuario confirma el guardado con un precio unitario nulo o menor o igual a cero
- **THEN** el formulario marca un error de precio inválido y no persiste el producto

### Requirement: Edición de producto
El sistema SHALL permitir modificar el nombre, el precio unitario y la tienda de un producto existente abriendo el formulario con los datos del producto precargados. Al confirmar, el sistema SHALL aplicar los mismos criterios de validación y guardar los cambios conservando el estado de habilitación y el id del producto.

#### Scenario: Editar un producto existente
- **WHEN** el usuario abre un producto para editar, modifica datos y confirma el guardado
- **THEN** el producto conserva su id y estado, y el listado refleja los nuevos datos

#### Scenario: Cancelar la edición
- **WHEN** el usuario abre un producto para editar y cancela sin guardar
- **THEN** no se modifica ningún dato del producto y el listado no cambia

### Requirement: Borrado de producto con confirmación
El sistema SHALL permitir iniciar el borrado de un producto deslizándolo en el listado. El sistema SHALL mostrar un diálogo de confirmación que indique que el producto desaparecerá de la lista de productos. Al confirmar, el sistema SHALL ocultar el producto del listado permanente (las listas de compra existentes que lo referencian SHALL conservar su nombre y precio); al cancelar, el producto SHALL permanecer sin cambios.

#### Scenario: Confirmar el borrado
- **WHEN** el usuario desliza un producto, el diálogo de confirmación aparece y el usuario confirma
- **THEN** el producto desaparece del listado de productos activos y no se muestra a menos que se registre nuevamente

#### Scenario: Cancelar el borrado
- **WHEN** el usuario desliza un producto, el diálogo de confirmación aparece y el usuario cancela
- **THEN** el producto permanece en el listado sin cambios

#### Scenario: Desaparece solo tras confirmar
- **WHEN** el usuario desliza un producto y responde el diálogo de confirmación
- **THEN** la fila no se oculta hasta que el usuario confirma; si cancela, la fila vuelve a su posición original