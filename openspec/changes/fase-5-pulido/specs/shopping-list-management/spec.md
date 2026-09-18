## ADDED Requirements

### Requirement: Ruta raíz redirige a Listas
El sistema SHALL exponer `/` como ruta raíz de la aplicación, SHALL redirigir esa ruta a la pantalla Listas (`/listas`) y SHALL mantener el arranque por defecto y la navegación inferior existentes sin alteraciones.

#### Scenario: Navegar a la raíz
- **WHEN** el usuario solicita la ruta raíz `/`
- **THEN** el sistema lo lleva a la pantalla Listas mostrando el listado de listas de compra

#### Scenario: Arranque por defecto intacto
- **WHEN** la aplicación se inicia sin una ruta solicitada
- **THEN** abre en la ruta por defecto actual (pestaña Productos)

#### Scenario: Navegación inferior persistente
- **WHEN** la ruta raíz redirige a Listas
- **THEN** las pestañas Productos y Listas siguen disponibles desde la navegación inferior