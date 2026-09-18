import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/data/models/product.dart';

void main() {
  group('Product.fromMap', () {
    test('mapea una fila SQL con precio numérico a double y activo a bool', () {
      final product = Product.fromMap({
        'id': 3,
        'nombre': 'Leche',
        'precio_unitario': 12.5,
        'tienda': 'Mercado Central',
        'activo': 1,
      });

      expect(product.id, 3);
      expect(product.nombre, 'Leche');
      expect(product.precioUnitario, 12.5);
      expect(product.precioUnitario, isA<double>());
      expect(product.tienda, 'Mercado Central');
      expect(product.activo, isTrue);
    });

    test('convierte un precio entero a double y activo 0 a deshabilitado', () {
      final product = Product.fromMap({
        'id': 9,
        'nombre': 'Pan',
        'precio_unitario': 5,
        'tienda': 'Panadería',
        'activo': 0,
      });

      expect(product.precioUnitario, 5.0);
      expect(product.precioUnitario, isA<double>());
      expect(product.activo, isFalse);
    });
  });

  group('Product.toMap', () {
    test('incluye el id cuando withId es true', () {
      final product = Product(
        id: 3,
        nombre: 'Leche',
        precioUnitario: 12.5,
        tienda: 'Mercado Central',
      );

      final map = product.toMap();

      expect(map['id'], 3);
      expect(map['nombre'], 'Leche');
      expect(map['precio_unitario'], 12.5);
      expect(map['tienda'], 'Mercado Central');
      expect(map['activo'], 1);
    });

    test('omite el id con withId false y codifica deshabilitado como 0', () {
      final product = Product(
        id: 3,
        nombre: 'Pan',
        precioUnitario: 5,
        tienda: 'Panadería',
        activo: false,
      );

      final map = product.toMap(withId: false);

      expect(map.containsKey('id'), isFalse);
      expect(map['activo'], 0);
    });
  });
}