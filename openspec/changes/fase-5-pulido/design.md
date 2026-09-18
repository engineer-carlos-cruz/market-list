## Context

Cambio pequeño y acotado sobre una base ya polida (ver proposal.md — Why). La navegación go_router existe con shell inferior (`/productos`, `/listas`, `/listas/:id` y sub-rutas); todos los modelos ya tienen `toMap`/`fromMap` (`Product`, `ShoppingList`, `ShoppingListItem`, `ListLine`) pero solo `ListLine` tiene test directo de mapeo. La suite pasa (69 tests) y `flutter analyze` está limpio.

## Goals / Non-Goals

**Goals:**
- Definir la ruta raíz `/` como redirección válida a `/listas` sin alterar la UX de arranque.
- Cerrar la cobertura de `toMap`/`fromMap` de los tres modelos sin tocar el código de dominio.
- Dejar la suite en verde y el análisis limpio como verificación final.

**Non-Goals:**
- No extraer `_total` de `lista_detalle_screen.dart` (el total queda cubierto por los widget tests existentes).
- No cambiar validaciones, estados vacíos ni el esquema DB.
- No agregar pantalla home ni dependencias nuevas.

## Decisions

**1. Ruta raíz con `redirect`, no pantalla home, ni cambio de arranque.**
En `lib/router.dart` se agrega una función de `redirect` en el `GoRouter` existente: si la ruta solicitada es exactamente `/`, redirige a `/listas`. `initialLocation` permanece en `/productos`, por lo que el arranque no cambia y la ruta `/` solo se ejercita por deep link o navegación explícita.
- Alternativa descartada: `initialLocation: '/'` — habría cambiado la pestaña de arranque a Listas sin pedirlo la consigna.
- Alternativa descartada: pantalla `home` en `/` — redundante con la navegación inferior ya existente.

**2. Test de navegación sobre el router real, no una config dedicada.**
Se reutiliza `pumpAppWithDb` (helpers de widget test) que monta `MaterialApp.router` con el `appRouter` real y una DB en memoria; el test navega/`push` a `/` y verifica que la pantalla resultante es el listado de Listas (rama activa del shell). Alternativa descartada: construir un `GoRouter` de test aislado — duplica config y no valida el router de producción.

**3. Tests de modelos por round-trip, patrón `list_line_test.dart`.**
Para `Product`, `ShoppingList` y `ShoppingListItem`, un test verifica `fromMap` contra el mapa SQL (tipos reales de sqflite) y otro verifica `toMap` (con `withId: true` y `withId: false`, `activo` como `1`/`0`, `fecha` en ISO). Se cubren casos borde: `precio_unitario` numérico con `.toDouble()`, fechas `DateTime.parse`, `id` ausente en `toMap(withId: false)`.

## Risks / Trade-offs

- [Redirect desprotegido] → El `redirect` se condiciona a `state.matchedLocation == '/'` para que `/listas` (y todas las demás rutas) nunca lo re-disparen; de lo contrario habría bucle.
- [`/` solo alcanzable por deep link] → Es el comportamiento buscado (la raíz existe y es válida), y el test de navegación lo fija explícitamente.
- [Tests de round-trip frágiles a cambios de filtros SQL] → Los tests verifican el contrato público de los modelos, no el repositorio; si cambia el byte-format de una columna, el test lo detecta pronto.