import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../state/providers/database_provider.dart';
import '../../state/providers/product_provider.dart';

double? parsePrecio(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '');
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

class ProductoFormScreen extends ConsumerStatefulWidget {
  const ProductoFormScreen({super.key, this.productoId});

  final int? productoId;

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _tiendaController = TextEditingController();
  bool _prefilled = false;

  bool get _esEdicion => widget.productoId != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _tiendaController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'El nombre es obligatorio';
    return null;
  }

  String? _validarTienda(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'La tienda es obligatoria';
    return null;
  }

  String? _validarPrecio(String? raw) {
    final precio = parsePrecio(raw ?? '');
    if (precio == null) return 'Ingresa un precio válido';
    if (precio <= 0) return 'El precio debe ser mayor a cero';
    return null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nombre = _nombreController.text.trim();
    final tienda = _tiendaController.text.trim();
    final precio = parsePrecio(_precioController.text)!;
    final db = await ref.read(databaseProvider.future);
    final repo = ProductRepository(db);
    if (_esEdicion) {
      await repo.update(Product(
        id: widget.productoId,
        nombre: nombre,
        precioUnitario: precio,
        tienda: tienda,
      ));
    } else {
      await repo.insert(Product(
        nombre: nombre,
        precioUnitario: precio,
        tienda: tienda,
      ));
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productProvider);
    final producto = _buscarProducto(productosAsync.value);
    if (producto == null && _esEdicion && productosAsync.isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_prefilled && producto != null) {
      final formato = NumberFormat('#,##0.##', 'es_ES');
      _nombreController.text = producto.nombre;
      _precioController.text = formato.format(producto.precioUnitario);
      _tiendaController.text = producto.tienda;
      _prefilled = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('campo-nombre'),
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo-precio'),
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.next,
                validator: _validarPrecio,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo-tienda'),
                controller: _tiendaController,
                decoration: const InputDecoration(
                  labelText: 'Tienda',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _guardar(),
                validator: _validarTienda,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Product? _buscarProducto(List<Product>? productos) {
    if (!_esEdicion || productos == null) return null;
    for (final producto in productos) {
      if (producto.id == widget.productoId) return producto;
    }
    return null;
  }
}