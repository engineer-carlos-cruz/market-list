## Why

La app abre directamente en las pantallas de Productos/Listas sin ninguna barrera. Se necesita un acceso simple que pida usuario y contraseña antes de entrar, para que solo una persona (Carlos) acceda a la gestión de la lista de mercado.

## What Changes

- Nueva pantalla de login (`/login`) como punto de entrada de la app: campos de usuario y contraseña, con validación de campos vacíos.
- La contraseña se escribe oculta (`obscureText`) con toggle para revelarla/ocultarla.
- Validación de credenciales en memoria: solo matchea usuario `Carlos` y contraseña `123456789`. Sin persistencia: el estado de sesión vive en memoria y se reinicia al cerrar la app.
- Credenciales inválidas muestran un SnackBar: "Usuario o contraseña incorrectos". Los campos vacíos muestran el mensaje "Ingresá tu usuario" / "Ingresá tu contraseña".
- Protección de rutas vía redirect en go_router: sin sesión, toda ruta deriva a `/login`; con sesión, `/login` deriva a `/listas`.
- Botón "Cerrar sesión" en el AppBar del shell que vuelve a `/login` sin reiniciar la app.
- Tests: los tests que levantan el router completo se inicializan autenticados por defecto; se agregan tests dedicados al login (credenciales correctas, incorrectas, campos vacíos, logout y redirect).

## Capabilities

### New Capabilities
- `login`: flujo de autenticación local sin persistencia (sesión en memoria), validación de credenciales fijas, pantalla de login, protección de rutas y cierre de sesión.

### Modified Capabilities

## Impact

- `lib/router.dart`: nueva ruta `/login`, `initialLocation` pasa a `/login`, redirect de autenticación.
- Nuevo `lib/state/providers/auth_provider.dart`: `AuthNotifier` (estado de sesión en memoria) usando Riverpod.
- Nuevo `lib/ui/ingreso/login_screen.dart` (o `lib/ui/auth/`): pantalla de login.
- AppBar del shell en `lib/router.dart`: acción "Cerrar sesión".
- Tests afectados: `test/helpers/widget_test_helpers.dart` y los 5 archivos que usan `pumpAppWithDb` (`navegacion_test`, `flujo_completo_test`, `productos_screen_test`, `listas_screen_test`, `crear_lista_screen_test`, `producto_form_screen_test`).
- Sin cambios de esquema DB, sin dependencias nuevas (solo stock de Flutter y paquetes ya presentes).