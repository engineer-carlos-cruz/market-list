import 'package:go_router/go_router.dart';

import 'ui/productos/producto_form_screen.dart';
import 'ui/productos/productos_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/productos',
  routes: [
    GoRoute(
      path: '/productos',
      name: 'productos',
      builder: (context, state) => const ProductosScreen(),
      routes: [
        GoRoute(
          path: 'nuevo',
          name: 'producto_nuevo',
          builder: (context, state) => const ProductoFormScreen(),
        ),
        GoRoute(
          path: ':id/editar',
          name: 'producto_editar',
          builder: (context, state) => ProductoFormScreen(
            productoId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);