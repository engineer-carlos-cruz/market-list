## Purpose

Brinda acceso protegido a la app Market List mediante un login local sin persistencia: la sesión vive solo en memoria y se valida contra credenciales fijas grabadas en el código.

## ADDED Requirements

### Requirement: Apertura en login sin sesión previa

Al iniciar la app, el sistema SHALL mostrar la pantalla de login cuando no existe una sesión activa, y NO mostrará ninguna funcionalidad interna (Productos, Listas) hasta autenticarse.

#### Scenario: Arranque sin sesión

- **WHEN** el usuario abre la app sin sesión activa en memoria
- **THEN** el sistema muestra la pantalla de login con los campos de usuario y contraseña
- **AND** no muestra las pantallas internas Productos y Listas

### Requirement: Validación de credenciales fijas

El sistema SHALL autenticar al usuario únicamente cuando el usuario es `Carlos` y la contraseña es `123456789`, sin verificación persistente ni llamada a red. Con credenciales inválidas el sistema SHALL permanecer en login y mostrar un SnackBar con el mensaje "Usuario o contraseña incorrectos".

#### Scenario: Credenciales válidas

- **WHEN** el usuario ingresa `Carlos` como usuario, `123456789` como contraseña y envía el formulario
- **THEN** el sistema activa la sesión y navega a la pantalla de Listas

#### Scenario: Credenciales inválidas

- **WHEN** el usuario ingresa credenciales que no matchean `Carlos`/`123456789` y envía el formulario
- **THEN** el sistema mantiene la sesión inactiva y muestra el SnackBar "Usuario o contraseña incorrectos"

### Requirement: Validación de campos vacíos

El sistema SHALL rechazar el envío del formulario si el usuario o la contraseña están vacíos, mostrando un mensaje de error en el campo correspondiente y sin mostrar el SnackBar de credenciales inválidas.

#### Scenario: Usuario vacío

- **WHEN** el usuario deja vacío el campo de usuario y envía el formulario
- **THEN** el sistema muestra el mensaje "Ingresá tu usuario" en el campo de usuario
- **AND** no muestra el SnackBar "Usuario o contraseña incorrectos"

#### Scenario: Contraseña vacía

- **WHEN** el usuario deja vacío el campo de contraseña y envía el formulario
- **THEN** el sistema muestra el mensaje "Ingresá tu contraseña" en el campo de contraseña
- **AND** no muestra el SnackBar "Usuario o contraseña incorrectos"

#### Scenario: Ambos campos vacíos

- **WHEN** el usuario envía el formulario con usuario y contraseña vacíos
- **THEN** el sistema muestra ambos mensajes de error en sus campos correspondientes

### Requirement: Contraseña oculta con alternancia de visibilidad

El sistema SHALL ocultar el texto de la contraseña por defecto y permitir alternar entre oculta y visible mediante un control junto al campo.

#### Scenario: Alternar visibilidad de la contraseña

- **WHEN** el usuario toca el control de visibilidad del campo de contraseña
- **THEN** el sistema alterna el texto de la contraseña entre oculto y visible
- **AND** el control refleja el estado actual

### Requirement: Protección de rutas

El sistema SHALL redirigir a `/login` cualquier ruta interna accedida sin sesión activa, y SHALL redirigir a `/listas` un acceso a `/login` con sesión activa.

#### Scenario: Ruta interna sin sesión

- **WHEN** un usuario sin sesión activa intenta acceder a una ruta interna (por ejemplo `/productos` o `/listas`)
- **THEN** el sistema redirige a `/login`

#### Scenario: Login con sesión activa

- **WHEN** un usuario con sesión activa accede a `/login`
- **THEN** el sistema redirige a `/listas`

### Requirement: Cierre de sesión

El sistema SHALL ofrecer una acción "Cerrar sesión" accesible desde las pantallas internas que desactive la sesión y devuelva al usuario a `/login`.

#### Scenario: Cerrar sesión desde Productos o Listas

- **WHEN** el usuario con sesión activa elige "Cerrar sesión" desde las pantallas internas
- **THEN** el sistema desactiva la sesión y muestra la pantalla de login
- **AND** el intento de acceder a una ruta interna devuelve nuevamente a `/login`

### Requirement: Sesión sin persistencia

El sistema SHALL mantener la sesión únicamente en memoria: al cerrar o reiniciar la app, la sesión se pierde y la próxima apertura exige volver a autenticarse.

#### Scenario: Reinicio de la app

- **WHEN** el usuario cierra la app con sesión activa y la vuelve a abrir
- **THEN** el sistema no recuerda la sesión anterior
- **AND** muestra la pantalla de login nuevamente