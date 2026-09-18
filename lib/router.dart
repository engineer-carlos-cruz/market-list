import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/listas/agregar_producto_screen.dart';
import 'ui/listas/crear_lista_screen.dart';
import 'ui/listas/lista_detalle_screen.dart';
import 'ui/listas/listas_screen.dart';
import 'ui/productos/producto_form_screen.dart';
import 'ui/productos/productos_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/productos',
  redirect: (context, state) {
    if (state.matchedLocation == '/') return '/listas';
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
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
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/listas',
              name: 'listas',
              builder: (context, state) => const ListasScreen(),
              routes: [
                GoRoute(
                  path: 'nueva',
                  name: 'lista_nueva',
                  builder: (context, state) => const CrearListaScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'lista_detalle',
                  builder: (context, state) => ListaDetalleScreen(
                    idLista: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'agregar',
                      name: 'lista_agregar',
                      builder: (context, state) => AgregarProductoScreen(
                        idLista: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Listas',
          ),
        ],
      ),
    );
  }
}