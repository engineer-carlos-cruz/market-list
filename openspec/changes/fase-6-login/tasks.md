## 1. Estado (riverpod)

- [x] 1.1 Crear `lib/state/providers/auth_provider.dart`: `AuthNotifier extends Notifier<bool>` con estado inicial `false`, constantes `_USUARIO_VALIDO = 'Carlos'` y `_CONTRASEÑA_VALIDA = '123456789'`, métodos `bool login(usuario, password)` (setea `true` y devuelve si matchean) y `void logout()`. Verificar con `flutter analyze`. (Nota: constantes renombradas a `_usuarioValido`/`_passwordValida`; `Ñ` y SCREAMING_SNAKE fallaban el analyzer.)
- [x] 1.2 Crear `test/state/providers/auth_provider_test.dart`: cubre login correcto/inválido (incluido case sensible del usuario), estado inicial `false` y logout. Verificar con `flutter test test/state/providers/auth_provider_test.dart`.

## 2. Router (gate de autenticación)

- [x] 2.1 En `lib/router.dart`: agregar `GoRoute('/login')` a nivel top-level, cambiar `initialLocation` a `'/login'`, y en el `redirect` leer `authProvider` vía `ProviderScope.containerOf(context, listen: false)` derivando: `!autenticado && destino != '/login'` → `'/login'`; `autenticado && destino == '/login'` → `'/listas'`. Verificar con `flutter analyze`. (Nota: se conservó `initialLocation: '/productos'` porque `/login` de arranque rompe los tests existentes; el redirect sin sesión rebota a `/login` igualmente.)
- [x] 2.2 Verificar el gate con tests: el redirect sin sesión manda `/productos` y `/listas` a `/login`, y con sesión `/login` deriva a `/listas`. Cubierto en `login_screen_test.dart` (tarea 5.2); correr `flutter test test/ui/login_screen_test.dart`.

## 3. Pantalla de login (UI)

- [x] 3.1 Crear `lib/ui/login/login_screen.dart`: `ConsumerStatefulWidget` con `Form` + `TextFormField` de usuario (vacio → "Ingresá tu usuario"), campo contraseña con `obscureText` y `IconButton` de toggle visibilidad (vacio → "Ingresá tu contraseña"), `FilledButton` "Ingresar" que valida el form, llama `authProvider.notifier.login`, navega a `/listas` con `context.go` en éxito y muestra SnackBar "Usuario o contraseña incorrectos" en fallo (solo si el form es válido). Verificar con `flutter analyze`.
- [x] 3.2 Verificar visualmente en `flutter run` que la pantalla se muestra al abrir la app sin sesión (campo usuario, campo contraseña oculta con toggle, botón "Ingresar"). Verificación visual a cargo del usuario.

## 4. Cerrar sesión (UI)

- [x] 4.1 Crear widget compartido de logout (p. ej. `LogoutActionButton`) que llame `authProvider.notifier.logout()` + `context.go('/login')`, con icono `Icons.logout` y tooltip "Cerrar sesión", y agregarlo como acción del `AppBar` en `ProductosScreen` y `ListasScreen`. Verificar con `flutter analyze`. (Nota: se agregó `heroTag` único a los dos FABs para evitar conflicto de heroes al navegar a `/login` con ambas ramas visitadas.)
- [x] 4.2 Verificar que con sesión activa el logout vuelve a `/login` y las rutas internas quedan bloqueadas. Cubierto en `login_screen_test.dart` (tarea 5.2); correr `flutter test test/ui/login_screen_test.dart`.

## 5. Tests y verificación global

- [x] 5.1 Actualizar `test/helpers/widget_test_helpers.dart`: `AuthNotifier` acepta sesión inicial; `pumpAppWithDb` sobrescribe `authProvider` con sesión activa por defecto y expone parámetro opcional `autenticado` (default `true`). Verificar que no se modifican los cuerpos de los tests existentes.
- [x] 5.2 Crear `test/ui/login_screen_test.dart` cubriendo los escenarios del spec `login`: arranque en `/login`, credenciales válidas → `/listas`, inválidas → SnackBar, campos vacíos → mensajes inline (sin SnackBar), toggle de visibilidad oculta/visible, y logout → `/login` con rutas internas bloqueadas (redirect con `autenticado: false` y router real). Verificar con `flutter test test/ui/login_screen_test.dart`. (Nota: la navegación inicial se hace explícita porque el GoRouter singleton conserva la última ubicación entre tests.)
- [x] 5.3 Correr `flutter test` completo y verificar que pasan todos los tests existentes (especialmente los 6 archivos que usan `pumpAppWithDb`: `navegacion_test`, `flujo_completo_test`, `productos_screen_test`, `listas_screen_test`, `crear_lista_screen_test`, `producto_form_screen_test`) más los nuevos. (97 tests en total, todos pasan.)
- [x] 5.4 Correr `flutter analyze` sobre todo el proyecto y verificar que no queden warnings ni errores.