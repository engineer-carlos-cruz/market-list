import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/list_line.dart';
import '../../data/models/shopping_list.dart';
import '../../data/models/shopping_list_item.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../state/providers/database_provider.dart';
import '../../state/providers/shopping_list_detail_provider.dart';
import '../../state/providers/shopping_list_provider.dart';
import '../formatos.dart';
import 'widgets/fila_producto.dart';

class ListaDetalleScreen extends ConsumerWidget {
  const ListaDetalleScreen({super.key, required this.idLista});

  final int idLista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listasAsync = ref.watch(shoppingListProvider);
    final detalleAsync = ref.watch(shoppingListDetailProvider(idLista));

    return Scaffold(
      appBar: AppBar(title: const Text('Lista')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/listas/$idLista/agregar'),
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
      body: detalleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar la lista: $error'),
          ),
        ),
        data: (lineas) => _CuerpoDetalle(
          lista: _buscarLista(listasAsync.value, idLista),
          lineas: lineas,
          total: _total(lineas),
        ),
      ),
      bottomNavigationBar: detalleAsync.hasValue
          ? _BarraTotal(total: _total(detalleAsync.value!))
          : null,
    );
  }
}

double _total(List<ListLine> lineas) {
  return lineas.fold(0, (sum, linea) => sum + linea.cantidad * linea.precioUnitario);
}

ShoppingList? _buscarLista(List<ShoppingList>? listas, int idLista) {
  if (listas == null) return null;
  for (final lista in listas) {
    if (lista.id == idLista) return lista;
  }
  return null;
}

class _CuerpoDetalle extends ConsumerWidget {
  const _CuerpoDetalle({
    required this.lista,
    required this.lineas,
    required this.total,
  });

  final ShoppingList? lista;
  final List<ListLine> lineas;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lineas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'La lista está vacía',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tocá el botón + para agregar productos',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      children: [
        if (lista != null) _Encabezado(lista: lista!),
        for (final linea in lineas)
          FilaProducto(
            linea: linea,
            onIncrementar: () =>
                _mutarCantidad(ref, linea, linea.cantidad + 1),
            onDecrementar: () => _decrementar(context, ref, linea),
          ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.lista});

  final ShoppingList lista;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lista.tienda, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            formatoFecha(lista.fecha),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BarraTotal extends StatelessWidget {
  const _BarraTotal({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
              Text(
                formatoMoneda(total),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _mutarCantidad(WidgetRef ref, ListLine linea, int cantidad) async {
  final db = await ref.read(databaseProvider.future);
  final repo = ShoppingListRepository(db);
  await repo.updateItem(ShoppingListItem(
    id: linea.id,
    idLista: linea.idLista,
    idProducto: linea.idProducto,
    cantidad: cantidad,
  ));
}

Future<void> _decrementar(
  BuildContext context,
  WidgetRef ref,
  ListLine linea,
) async {
  if (linea.cantidad > 1) {
    await _mutarCantidad(ref, linea, linea.cantidad - 1);
    return;
  }
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Quitar producto'),
      content: Text('"${linea.nombre}" se quitará de la lista.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Quitar'),
        ),
      ],
    ),
  );
  if (confirmado != true) return;
  final db = await ref.read(databaseProvider.future);
  final repo = ShoppingListRepository(db);
  await repo.removeItem(linea.id);
}