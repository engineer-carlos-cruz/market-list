import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/shopping_list.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../state/providers/database_provider.dart';
import '../../state/providers/store_provider.dart';

class CrearListaScreen extends ConsumerStatefulWidget {
  const CrearListaScreen({super.key});

  @override
  ConsumerState<CrearListaScreen> createState() => _CrearListaScreenState();
}

class _CrearListaScreenState extends ConsumerState<CrearListaScreen> {
  final _tiendaController = TextEditingController();
  bool _mostrarError = false;

  @override
  void initState() {
    super.initState();
    _tiendaController.addListener(_alCambiarTienda);
  }

  @override
  void dispose() {
    _tiendaController
      ..removeListener(_alCambiarTienda)
      ..dispose();
    super.dispose();
  }

  void _alCambiarTienda() {
    if (_mostrarError) setState(() => _mostrarError = false);
  }

  Future<void> _guardar() async {
    final tienda = _tiendaController.text.trim();
    if (tienda.isEmpty) {
      setState(() => _mostrarError = true);
      return;
    }
    final db = await ref.read(databaseProvider.future);
    final repo = ShoppingListRepository(db);
    await repo.insert(ShoppingList(
      tienda: tienda,
      fecha: DateTime.now(),
    ));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tiendasAsync = ref.watch(storeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva lista')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tiendasAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error al cargar las tiendas: $error'),
              data: (tiendas) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tiendas.isEmpty) ...[
                    Text(
                      'Aún no hay tiendas en el catálogo. Escribí el nombre de la tienda para esta lista.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownMenu<String>(
                    controller: _tiendaController,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Tienda'),
                    errorText: _mostrarError
                        ? 'La tienda es obligatoria'
                        : null,
                    dropdownMenuEntries: [
                      for (final tienda in tiendas)
                        DropdownMenuEntry(value: tienda, label: tienda),
                    ],
                    onSelected: (value) {
                      if (value != null) _tiendaController.text = value;
                    },
                    requestFocusOnTap: true,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _guardar,
                    child: const Text('Crear lista'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}