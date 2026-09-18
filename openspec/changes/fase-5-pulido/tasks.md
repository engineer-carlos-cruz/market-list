## 1. Navegación: ruta raíz `/`

- [x] 1.1 Agregar en `lib/router.dart` un `redirect` al `GoRouter` que envíe la ruta exacta `/` a `/listas` (condicionado a `state.matchedLocation == '/'`, sin cambiar `initialLocation`) y verificar que `flutter analyze` no reporta errores ni warnings
- [x] 1.2 Agregar un widget test de navegación que, montando la app real con `pumpAppWithDb`, navegue a `/` y verifique que la rama Listas queda activa (listado de listas y pestaña Listas seleccionada); verificar que pasa con `flutter test`

## 2. Tests unitarios de modelos (conversión toMap/fromMap)

- [x] 2.1 Crear `test/data/models/product_test.dart` cubriendo `fromMap` (precio numérico convertido a `double`, `activo` en 0/1) y `toMap` (con `withId: true` y `withId: false`); verificar que pasa con `flutter test`
- [x] 2.2 Crear `test/data/models/shopping_list_test.dart` cubriendo `fromMap` (fecha `DateTime.parse` sobre ISO) y `toMap` (con `withId: true` y `withId: false`, fecha ISO); verificar que pasa con `flutter test`
- [x] 2.3 Crear `test/data/models/shopping_list_item_test.dart` cubriendo `fromMap` y `toMap` (con `withId: true` y `withId: false`); verificar que pasa con `flutter test`

## 3. Verificación final

- [x] 3.1 Correr `flutter analyze` sin warnings y `flutter test` con toda la suite en verde (incluye los tests existentes de cálculo de total del detalle y los nuevos de navegación y modelos)