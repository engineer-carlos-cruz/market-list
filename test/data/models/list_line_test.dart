import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/list_line.dart';

void main() {
  group('ListLine.fromMap', () {
    test('mapea una fila del JOIN de ítem + producto', () {
      final line = ListLine.fromMap({
        'id': 7,
        'id_lista': 3,
        'id_producto': 12,
        'nombre': 'Leche',
        'precio_unitario': 12.5,
        'cantidad': 2,
        'activo': 1,
      });

      expect(line.id, 7);
      expect(line.idLista, 3);
      expect(line.idProducto, 12);
      expect(line.nombre, 'Leche');
      expect(line.precioUnitario, 12.5);
      expect(line.cantidad, 2);
      expect(line.activo, isTrue);
    });

    test('mapea un producto deshabilitado con activo en 0', () {
      final line = ListLine.fromMap({
        'id': 1,
        'id_lista': 1,
        'id_producto': 9,
        'nombre': 'Pan',
        'precio_unitario': 5,
        'cantidad': 1,
        'activo': 0,
      });

      expect(line.activo, isFalse);
      expect(line.nombre, 'Pan');
    });
  });
}