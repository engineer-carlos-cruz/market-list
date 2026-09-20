import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/shopping_list.dart';
import '../../state/providers/shopping_list_provider.dart';
import '../formatos.dart';
import '../widgets/alacena_logo.dart';
import '../widgets/logout_action_button.dart';

class ListasScreen extends ConsumerWidget {
  const ListasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listasAsync = ref.watch(shoppingListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas'),
        actions: const [LogoutActionButton()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-listas',
        onPressed: () => context.push('/listas/nueva'),
        tooltip: 'Nueva lista',
        child: const Icon(Icons.add),
      ),
      body: listasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar las listas: $error'),
          ),
        ),
        data: (listas) => listas.isEmpty
            ? const _EstadoVacio()
            : _ListaDeListas(listas: listas),
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
            AlacenaLogo(size: 64),
            const SizedBox(height: 16),
            Text(
              'Aún no hay listas',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tocá el botón + para crear tu primera lista de compras',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaDeListas extends ConsumerWidget {
  const _ListaDeListas({required this.listas});

  final List<ShoppingList> listas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: listas.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final lista = listas[index];
        return ListTile(
          title: Text(lista.tienda),
          subtitle: Text(formatoFecha(lista.fecha)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/listas/${lista.id}'),
        );
      },
    );
  }
}