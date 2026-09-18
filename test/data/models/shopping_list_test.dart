import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/shopping_list.dart';

void main() {
  group('ShoppingList.fromMap', () {
    test('mapea una fila SQL parseando la fecha ISO', () {
      final list = ShoppingList.fromMap({
        'id': 5,
        'tienda': 'Mercado Central',
        'fecha': '2026-09-13T10:00:00.000',
      });

      expect(list.id, 5);
      expect(list.tienda, 'Mercado Central');
      expect(list.fecha, DateTime.parse('2026-09-13T10:00:00.000'));
    });
  });

  group('ShoppingList.toMap', () {
    test('incluye el id y codifica la fecha ISO cuando withId es true', () {
      final list = ShoppingList(
        id: 5,
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 13),
      );

      final map = list.toMap();

      expect(map['id'], 5);
      expect(map['tienda'], 'Mercado Central');
      expect(map['fecha'], DateTime(2026, 9, 13).toIso8601String());
    });

    test('omite el id con withId false', () {
      final list = ShoppingList(
        tienda: 'Mercado Central',
        fecha: DateTime(2026, 9, 13),
      );

      final map = list.toMap(withId: false);

      expect(map.containsKey('id'), isFalse);
      expect(map['tienda'], 'Mercado Central');
    });
  });
}