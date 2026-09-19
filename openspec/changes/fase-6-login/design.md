## Context

See proposal.md - Why. Estado actual relevante:

- `lib/router.dart` define un `GoRouter` con `initialLocation: '/'` y un `StatefulShellRoute.indexedStack` con dos ramas (`/productos`, `/listas`). No hay ruta de login ni lógica de sesión.
- `main.dart` monta `ProviderScope(child: MaterialApp.router(...))`: el router vive **bajo** el `ProviderScope`, por lo que su `redirect` puede leer providers vía `ProviderScope.containerOf(context, listen: false)`.
- Estado gestionado con `flutter_riverpod` 2.x (patrón `Notifier`). Sin dependencias de red; sesión 100% local.
- Tests de widgets que levantan el router completo usan `pumpAppWithDb` (`test/helpers/widget_test_helpers.dart`), que hoy solo sobrescribe `databaseProvider`.

## Goals / Non-Goals

**Goals:**
- Gate de autenticación en el router con estado en memoria (sin persistencia, sin tocar sqflite).
- Un único lugar donde se define si hay sesión, consumido tanto por UI (login, logout) como por el router (redirect).
- Minimizar el impacto sobre los tests existentes que ya asumen app autenticada.

**Non-Goals:**
- Persistencia de sesión (login solo a la apertura; al reiniciar se vuelve a pedir).
- Múltiples usuarios, registro, recuperación de contraseña ni backend.
- Encripción/gestión segura de credenciales (la contraseña queda hardcodeada y en claro; es una aceptación expresada del requisito "sin persistencia por ahora").

## Decisions

### Estado de sesión: `NotifierProvider<AuthNotifier, bool>` en memoria

Nuevo `lib/state/providers/auth_provider.dart`:

- `AuthNotifier extends Notifier<bool>`, estado inicial `false`.
- `bool login(String usuario, String password)`: compara contra constantes `_USUARIO_VALIDO = 'Carlos'` y `_CONTRASEÑA_VALIDA = '123456789'`; setea `true` si matchean y devuelve el resultado. No persiste nada.
- `void logout()`: setea `false`.
- Credenciales en una única constante compartida para facilitar cambios futuros.

Alternativa considerada: guardar en SQLite. Se descarta: el requisito es explícitamente sin persistencia y la app es de un solo usuario; agregar una tabla sin uso real agrega migración sin beneficio.

### Gate en el router sin `refreshListenable`

Nuevo estado del router en `lib/router.dart`:

```
initialLocation: '/login'

redirect(context, state):
  final autenticado = leer authProvider (via container del ProviderScope)

  si !autenticado y destino != /login  -> '/login'
  si  autenticado y destino == /login  -> '/listas'
  else -> null
```

- Se lee el estado con `ProviderScope.containerOf(context, listen: false).read(authProvider)`; el router siempre se construye bajo `ProviderScope`, así que es seguro.
- **No** se usa `refreshListenable`: tras un login exitoso la UI navega explícitamente con `context.go('/listas')`, y el redirect de go_router se evalúa en cada navegación; el estado ya está actualizado para entonces. `refreshListenable` solo haría falta si hubiera redirecciones *no* iniciadas por navegación.
- `'/login'` se agrega como `GoRoute` top-level (fuera del shell), sin bottom nav.

Alternativa considerada: un `ValueNotifier` puente entre el notifier y `refreshListenable`. Se descarta por innecesario: elegimos navegación explícita post-login y post-logout, patrón ya usado en la app (navegación por `context.go`/`push`).

### Pantalla de login: `lib/ui/login/login_screen.dart`

`ConsumerStatefulWidget` con un `Form` y `TextFormField`s:

- Campo usuario: validator → si vacío, escribe "Ingresá tu usuario".
- Campo contraseña: `obscureText` alternable con `IconButton` (Icon `visibility`/`visibility_off`) al final del campo, estado en `setState`; validator → si vacío, "Ingresá tu contraseña".
- Botón `FilledButton` "Ingresar" (estilo de la app). Al tocar valida el form; si es válido llama `ref.read(authProvider.notifier).login(...)`:
  - `true` → `context.go('/listas')`.
  - `false` → `ScaffoldMessenger` muestra SnackBar "Usuario o contraseña incorrectos" (sin navegar).
- Si el form no es válido solo se muestran los errores inline; nunca el SnackBar.
- La pantalla no muestra AppBar con retroceso (es la raíz de la sesión); contenido centrado con padding, usando el `TextTheme` del tema (seed `teal`), siguiendo el patrón visual de las pantallas existentes (sin paquetes extra).

### Logout: acción "Cerrar sesión" en los AppBars de las pantallas raíz

El shell actual NO tiene AppBar propio (cada pantalla muestra su propio `AppBar`). Para no duplicar AppBars anidados ni refactorizar todos los screens, la acción se agrega como `IconButton` (icono `Icons.logout`, tooltip "Cerrar sesión") en el `AppBar` de `ProductosScreen` y `ListasScreen` (las dos pantallas raíz de las ramas). Para evitar duplicación se crea un pequeño widget compartido (p. ej. `LogoutActionButton`) que hace `ref.read(authProvider.notifier).logout()` + `context.go('/login')`; el redirect confirma el estado y no deja volver adentro.

Alternativa considerada: migrar el AppBar al `_ShellScaffold`. Se descarta: tocaría todas las pantallas (detalle, formularios, etc.) y expande el alcance sin valor para esta fase.

### Tests: helper autenticado por defecto + tests dedicados de login

- `test/helpers/widget_test_helpers.dart`: `AuthNotifier` acepta sesión inicial. `pumpAppWithDb` pasa a sobrescribir **también** `authProvider` con una sesión activa por defecto (parámetro opcional `autenticado` en el helper, `true` por defecto). Así los 5 archivos que usan el helper (`navegacion_test`, `flujo_completo_test`, `productos_screen_test`, `listas_screen_test`, `crear_lista_screen_test`, `producto_form_screen_test`) siguen pasando sin tocar sus cuerpos.
- Nuevo `test/ui/login_screen_test.dart` cubre los escenarios del spec: arranque en login, credenciales válidas → `/listas`, inválidas → SnackBar, campos vacíos → mensajes inline, toggle de visibilidad, logout → vuelve a `/login` y las rutas internas quedan bloqueadas. Los tests de redirect usan el router real (`pumpAppWithDb` con `autenticado: false`).
- Los tests que usan `pumpWithDb` (pantalla suelta sin router) no se ven afectados.

## Risks / Trade-offs

- [Credenciales hardcodeadas y en claro] → Mitigation: constantes en un único archivo (`auth_provider.dart`); el requisito es explícitamente temporal ("sin persistencia por ahora"); un futuro cambio de autenticación solo toca ese punto.
- [Redirect leyendo el provider con `containerOf`] → Mitigation: `MaterialApp.router` siempre está bajo `ProviderScope` en `main.dart`; los tests de flujo real cubren el redirect con el router completo.
- [Tests existentes rompen al cambiar `initialLocation`] → Mitigation: default autenticado en `pumpAppWithDb` + parámetro `autenticado` para tests de login; no se modifica el cuerpo de los tests existentes.
- [Sin `refreshListenable`, el redirect depende de navegación explícita tras login/logout] → Mitigation: ambos flujos navegan explícitamente (`context.go`); si aparece un camino que cambie el estado sin navegar (p. ej. timeout de sesión), se migra a `refreshListenable`.
- [Logout solo en pantallas raíz; las de detalle no lo muestran] → Aceptado: el requisito es "accesible desde las pantallas internas", se cumple; agregarlo a todos los AppBars es ruido visual.