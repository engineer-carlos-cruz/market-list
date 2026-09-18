import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/shopping_list_item.dart';

void main() {
  group('ShoppingListItem.fromMap', () {
    test('mapea una fila SQL', () {
      final item = ShoppingListItem.fromMap({
        'id': 9,
        'id_lista': 3,
        'id_producto': 12,
        'cantidad': 4,
      });

      expect(item.id, 9);
      expect(item.idLista, 3);
      expect(item.idProducto, 12);
      expect(item.cantidad, 4);
    });
  });

  group('ShoppingListItem.toMap', () {
    test('incluye el id cuando withId es true', () {
      final item = ShoppingListItem(
        id: 9,
        idLista: 3,
        idProducto: 12,
        cantidad: 4,
      );

      final map = item.toMap();

      expect(map['id'], 9);
      expect(map['id_lista'], 3);
      expect(map['id_producto'], 12);
      expect(map['cantidad'], 4);
    });

    test('omite el id con withId false', () {
      final item = ShoppingListItem(
        idLista: 3,
        idProducto: 12,
        cantidad: 2,
      );

      final map = item.toMap(withId: false);

      expect(map.containsKey('id'), isFalse);
      expect(map['id_lista'], 3);
      expect(map['id_producto'], 12);
      expect(map['cantidad'], 2);
    });
  });
}