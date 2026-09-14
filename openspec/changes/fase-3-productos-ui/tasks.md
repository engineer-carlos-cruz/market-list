## 1. Navegación y arranque

- [x] 1.1 Crear `lib/router.dart` con un `GoRouter` que defina las rutas `/productos` (home), `/productos/nuevo` y `/productos/:id/editar`, y verificar que compila y las tres rutas resuelven a sus pantallas (los widgets se crean en las secciones siguientes)
- [x] 1.2 Actualizar `lib/main.dart`: `MaterialApp.router(routerConfig: AppRouter.router)`, reemplazando el `home: "Hello World"`, y verificar que `flutter analyze` pasa sin warnings y la app compila

## 2. Pantalla Productos (listado)

- [x] 2.1 Crear `lib/ui/productos/productos_screen.dart`: `ConsumerWidget` que observa `productProvider` con `ref.watch`, maneja los estados del `AsyncValue` (carga/error/vacío/datos) y renderiza cada producto con nombre, precio unitario formateado (`intl`, es_ES) y tienda; verificar con test de widgets que la lista pinta los datos de los productos activos
- [x] 2.2 Implementar el estado vacío: mensaje en español con invitación a crear el primer producto, y el FAB/acción de alta que navega a `/productos/nuevo`; verificar con test que sin productos se muestra el mensaje y el FAB conduce al formulario
- [x] 2.3 Verificar que una mutación (alta/edición) realizada desde otra parte refresca el listado solo (envío por señal de cambio); verificar con test que tras insertar el listado se actualiza sin interacción

## 3. Borrado por swipe con confirmación

- [x] 3.1 Envolver cada fila en `Dismissible` con `confirmDismiss`, abriendo un `AlertDialog` de confirmación (texto: el producto "desaparecerá de la lista de productos" y acciones Cancelar/Eliminar); verificar con test que deslizar abre el diálogo y que cancelar deja la fila intacta
- [x] 3.2 Conectar la confirmación al borrado: al aceptar, construir el `ProductRepository` a partir de `databaseProvider.future` e invocar `disable(id)`; verificar con test que al confirmar el producto sale del listado y que una lista de compra existente que lo referencia conserva su nombre y precio (consulta directa a la DB)

## 4. Formulario de alta/edición

- [x] 4.1 Crear `lib/ui/productos/producto_form_screen.dart` con un `Form` de campos nombre, precio unitario y tienda, y validadores en español: nombre y tienda obligatorios (sin whitespace), precio `> 0` con parseo decimal es_ES (acepta coma y punto); verificar con widget tests que cada error se muestra y que no se persiste nada inválido
- [x] 4.2 Implementar el alta: al guardar con datos válidos, `repo.insert(Product(...))` con `activo` por defecto y `context.pop()`; verificar con test que el producto queda persistido y la pantalla vuelve al listado que ya lo muestra
- [x] 4.3 Implementar la edición: la ruta `/productos/:id/editar` precarga el producto existente en el formulario y guarda con `repo.update(product)` (conservando id y `activo`); verificar con test que los datos aparecen precargados, que editar modifica los campos y que guardar refleja el cambio en el listado; verificar también que cancelar deja los datos sin cambios

## 5. Infraestructura de tests de widgets

- [x] 5.1 Crear helpers en `test/helpers/`: utilidad que monta una pantalla dentro de `ProviderScope` con `databaseProvider` overrideado a una DB en memoria (`openInMemoryDatabase`), siguiendo el patrón de `createTestContainer` de fase 2; verificar con un test de humo que el helper monta `ProductosScreen` sin errores
- [x] 5.2 Combinar el helper con el router real para los tests de navegación (FAB -> `/productos/nuevo`, guardar -> vuelve al listado); verificar con tests de integración de widgets que las rutas navegan y el formulario completa el flujo

## 6. Verificación final

- [x] 6.1 Ejecutar `flutter analyze` y confirmar cero errores y cero warnings en `lib/` y `test/`
- [x] 6.2 Ejecutar `flutter test` y confirmar que toda la suite pasa (incluidos tests de fases 1 y 2); confirmar que ni `app_database.dart`, ni el esquema DB, ni el contrato de los providers fueron modificados