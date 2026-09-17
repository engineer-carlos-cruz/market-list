import 'package:flutter/material.dart';

import '../../../data/models/list_line.dart';
import '../../formatos.dart';

class FilaProducto extends StatelessWidget {
  const FilaProducto({
    super.key,
    required this.linea,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final ListLine linea;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(linea.nombre),
      subtitle: Text(formatoMoneda(linea.precioUnitario)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrementar,
            tooltip: 'Disminuir cantidad',
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${linea.cantidad}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onIncrementar,
            tooltip: 'Aumentar cantidad',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}