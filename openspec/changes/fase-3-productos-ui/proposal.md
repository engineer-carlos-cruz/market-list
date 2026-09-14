## Why

Las fases 1 y 2 dejaron la capa de datos y el estado Riverpod de productos y listas listos y probados, pero la app sigue mostrando "Hello World" en `main.dart`: no hay una sola pantalla de negocio. Fase 3 da el primer salto a la UI con la gestión completa de productos (listado, alta/edición, borrado), dejando el `main.dart` conectado a una navegación real (`go_router`, ya declarado pero sin usar) sobre la que la fase de Listas podrá montarse sin reestructurar la raíz.

## What Changes

- **Pantalla Productos**: lista reactiva de productos activos (nombre + precio + tienda) alimentada por `productProvider`, con línea de borrado mediante swipe + diálogo de confirmación y una acción de alta (FAB).
- **Formulario de alta/edición**: pantalla completa con campos nombre, precio unitario y tienda; validación en español (nombre y tienda obligatorios, precio mayor a cero); edición precargando el producto existente.
- **Navegación go_router**: rutas raíz `/productos` (home), `/productos/nuevo` (alta) y `/productos/:id/editar` (edición), cableadas en `main.dart`. Sin shell de navegación inferior en esta fase.
- **Semántica de borrado**: swipe + confirmación deshabilita el producto (borrado suave ya soportado por `ProductRepository.disable`); el diálogo comunica la desaparición del listado sin afirmar borrado físico. No se agrega `delete()` físico.
- **Acciones de mutación**: los widgets disparan `insert`/`update`/`disable` a través de la capa de estado, apoyándose en la señal de cambio compartida del repositorio para que `productProvider` se refresque solo (no se introducen providers nuevos de acción).
- **Tests de widgets**: infraestructura nueva (`ProviderScope` con overrides + DB en memoria) y tests por pantalla, siguiendo el patrón de `ProviderContainer` de fase 2.

## Capabilities

### New Capabilities
- `product-management`: gestión de productos desde la UI — pantalla de listado con swipe de borrado y diálogo de confirmación, formulario de alta/edición con validación, y navegación por rutas go_router sobre los providers de fase 2.

### Modified Capabilities
- Ninguna: la reactividad y el ciclo de vida de `products` ya están especificados en fase 1; la UI solo los consume.

## Impact

- **Nuevos archivos**: `lib/ui/` (pantalla de productos, formulario, router/`AppRouter` en `lib/router.dart` o similar) y helpers de test de widgets (`test/helpers/`), más los tests de cada pantalla.
- **Modificados**: `lib/main.dart` (de "Hello World" pasa a `MaterialApp.router` con `AppRouter`) y `pubspec.yaml` solo si `go_router` requiriera ajuste de versión (ya está declarado en `^14.8.1`).
- **Dependencias**: ninguna nueva — `go_router` e `intl` ya están en `pubspec.yaml`; UI con stock de Material.
- **Esquema DB**: sin cambios de esquema ni migración; el borrado suave ya existe (`activo`).
- **Sin red**: todo sigue 100% local.