import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/list_line.dart';
import '../../data/models/product.dart';
import '../../data/models/shopping_list_item.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../state/providers/database_provider.dart';
import '../../state/providers/product_provider.dart';
import '../../state/providers/shopping_list_detail_provider.dart';
import '../formatos.dart';

class AgregarProductoScreen extends ConsumerStatefulWidget {
  const AgregarProductoScreen({super.key, required this.idLista});

  final int idLista;

  @override
  ConsumerState<AgregarProductoScreen> createState() =>
      _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends ConsumerState<AgregarProductoScreen> {
  String _query = '';

  Future<void> _agregar(Product producto) async {
    final db = await ref.read(databaseProvider.future);
    final repo = ShoppingListRepository(db);
    try {
      await repo.insertItem(ShoppingListItem(
        idLista: widget.idLista,
        idProducto: producto.id!,
        cantidad: 1,
      ));
    } on ArgumentError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El producto ya está en la lista')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productProvider);
    final detalleAsync = ref.watch(shoppingListDetailProvider(widget.idLista));
    final presentes = <int>{
      for (final linea in detalleAsync.value ?? const <ListLine>[])
        linea.idProducto,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('buscador-productos'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (productos) {
                final visibles = _filtrar(productos, _query);
                if (visibles.isEmpty) {
                  return const Center(child: Text('No hay productos que coincidan'));
                }
                return ListView.separated(
                  itemCount: visibles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final producto = visibles[index];
                    final yaEsta = presentes.contains(producto.id);
                    return ListTile(
                      title: Text(producto.nombre),
                      subtitle: Text('${producto.tienda} · ${formatoMoneda(producto.precioUnitario)}'),
                      enabled: !yaEsta,
                      trailing: yaEsta
                          ? const Icon(Icons.check_circle)
                          : null,
                      onTap: () => _agregar(producto),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<Product> _filtrar(List<Product> productos, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return productos;
  return [
    for (final producto in productos)
      if (producto.nombre.toLowerCase().contains(q)) producto,
  ];
}