class ListLine {
  const ListLine({
    required this.id,
    required this.idLista,
    required this.idProducto,
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    required this.activo,
  });

  final int id;
  final int idLista;
  final int idProducto;
  final String nombre;
  final double precioUnitario;
  final int cantidad;
  final bool activo;

  factory ListLine.fromMap(Map<String, Object?> map) {
    return ListLine(
      id: map['id'] as int,
      idLista: map['id_lista'] as int,
      idProducto: map['id_producto'] as int,
      nombre: map['nombre'] as String,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      cantidad: map['cantidad'] as int,
      activo: (map['activo'] as int) == 1,
    );
  }

  ListLine copyWith({int? cantidad}) {
    return ListLine(
      id: id,
      idLista: idLista,
      idProducto: idProducto,
      nombre: nombre,
      precioUnitario: precioUnitario,
      cantidad: cantidad ?? this.cantidad,
      activo: activo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListLine &&
        other.id == id &&
        other.idLista == idLista &&
        other.idProducto == idProducto &&
        other.nombre == nombre &&
        other.precioUnitario == precioUnitario &&
        other.cantidad == cantidad &&
        other.activo == activo;
  }

  @override
  int get hashCode => Object.hash(
        id,
        idLista,
        idProducto,
        nombre,
        precioUnitario,
        cantidad,
        activo,
      );

  @override
  String toString() {
    return 'ListLine(id: $id, idLista: $idLista, idProducto: $idProducto, '
        'nombre: $nombre, precioUnitario: $precioUnitario, '
        'cantidad: $cantidad, activo: $activo)';
  }
}