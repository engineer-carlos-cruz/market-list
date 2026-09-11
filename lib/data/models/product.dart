class Product {
  const Product({
    this.id,
    required this.nombre,
    required this.precioUnitario,
    required this.tienda,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final double precioUnitario;
  final String tienda;
  final bool activo;

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      tienda: map['tienda'] as String,
      activo: (map['activo'] as int) == 1,
    );
  }

  Map<String, Object?> toMap({bool withId = true}) {
    return {
      if (withId && id != null) 'id': id,
      'nombre': nombre,
      'precio_unitario': precioUnitario,
      'tienda': tienda,
      'activo': activo ? 1 : 0,
    };
  }

  Product copyWith({
    int? id,
    String? nombre,
    double? precioUnitario,
    String? tienda,
    bool? activo,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      tienda: tienda ?? this.tienda,
      activo: activo ?? this.activo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.nombre == nombre &&
        other.precioUnitario == precioUnitario &&
        other.tienda == tienda &&
        other.activo == activo;
  }

  @override
  int get hashCode =>
      Object.hash(id, nombre, precioUnitario, tienda, activo);

  @override
  String toString() {
    return 'Product(id: $id, nombre: $nombre, '
        'precioUnitario: $precioUnitario, tienda: $tienda, activo: $activo)';
  }
}