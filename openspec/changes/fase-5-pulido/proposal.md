## Why

Fase 5 cierra la entrega con el pulido que pide la consigna (ítems 10-12): ruta raíz `/` en go_router, estados vacíos y validaciones de cantidades, y tests básicos de conversión y análisis. Las fases 1-4 ya dejaron go_router con el shell inferior, los estados vacíos ("Aún no hay productos", "Aún no hay listas", "La lista está vacía"), validaciones de cantidad > 0 en el repositorio y una suite de 69 tests en verde; lo que falta es la ruta `/` (hoy la app arranca en `/productos` y no existe una raíz) y tests unitarios directos de `toMap`/`fromMap` para `Product`, `ShoppingList` y `ShoppingListItem`.

## What Changes

- **Ruta raíz `/:`** en `router.dart` que redirige a `/listas` mediante `redirect` de go_router; `initialLocation` sigue en `/productos` para no alterar la pantalla de arranque. La ruta queda definida, válida y cubierta por un test de navegación que aterriza en la rama Listas.
- **Tests unitarios de modelos**: nuevos `product_test.dart`, `shopping_list_test.dart` y `shopping_list_item_test.dart` cubriendo el round-trip `toMap`/`fromMap` (`activo` como 0/1, `withId`, fecha ISO, tipos numéricos), siguiendo el patrón de `list_line_test.dart`.
- **Sin cambios en validaciones ni estados vacíos**: ya están cubiertos por fases previas (mensajes de vacío y rechazo de `cantidad <= 0` en `insertItem`/`updateItem`, con el stepper sin bajar de 1).
- **Cálculo de total sin tocar**: permanece cubierto por los widget tests del detalle (`$25,00`, stepper, lista vacía); no se extrae `_total` de `lista_detalle_screen.dart` (decisión de exploración).
- **Verificación final**: `flutter analyze` sin warnings y `flutter test` con toda la suite en verde.

## Capabilities

### New Capabilities
- Ninguna.

### Modified Capabilities
- `shopping-list-management`: se agrega el requisito de ruta raíz de navegación — `/` como ruta de entrada delegada que redirige a la pantalla Listas, junto con la navegación inferior ya existente.

## Impact

- **Modificados**: `lib/router.dart` (redirect `/` → `/listas`).
- **Nuevos**: tests unitarios de modelos (`test/data/models/product_test.dart`, `shopping_list_test.dart`, `shopping_list_item_test.dart`) y un test de navegación que ejercita `/` (reusando `pumpAppWithDb` de `widget_test_helpers.dart`).
- **Dependencias**: ninguna nueva — `go_router` y `flutter_test` ya están declarados.
- **Esquema DB**: sin cambios ni migración (v1).
- **Sin red**: todo sigue 100% local.