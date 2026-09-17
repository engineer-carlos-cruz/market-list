import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../state/providers/database_provider.dart';
import '../../state/providers/product_provider.dart';
import '../formatos.dart';

String formatPrecio(Product producto) => formatoMoneda(producto.precioUnitario);

class ProductosScreen extends ConsumerWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/productos/nuevo'),
        tooltip: 'Nuevo producto',
        child: const Icon(Icons.add),
      ),
      body: productosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar productos: $error'),
          ),
        ),
        data: (productos) => productos.isEmpty
            ? const _EstadoVacio()
            : _ListaProductos(productos: productos),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay productos',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tocá el botón + para crear tu primer producto',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaProductos extends ConsumerWidget {
  const _ListaProductos({required this.productos});

  final List<Product> productos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: productos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final producto = productos[index];
        return Dismissible(
          key: ValueKey(producto.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmarBorrado(context, ref, producto),
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: ListTile(
            title: Text(producto.nombre),
            subtitle: Text(producto.tienda),
            trailing: Text(
              formatPrecio(producto),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => context.push('/productos/${producto.id}/editar'),
          ),
        );
      },
    );
  }
}

Future<bool> _confirmarBorrado(
  BuildContext context,
  WidgetRef ref,
  Product producto,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar producto'),
      content: Text(
        '"${producto.nombre}" desaparecerá de la lista de productos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmado != true) return false;
  final db = await ref.read(databaseProvider.future);
  final repo = ProductRepository(db);
  await repo.disable(producto.id!);
  return false;
}