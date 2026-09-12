class ShoppingListItem {
  const ShoppingListItem({
    this.id,
    required this.idLista,
    required this.idProducto,
    required this.cantidad,
  });

  final int? id;
  final int idLista;
  final int idProducto;
  final int cantidad;

  factory ShoppingListItem.fromMap(Map<String, Object?> map) {
    return ShoppingListItem(
      id: map['id'] as int?,
      idLista: map['id_lista'] as int,
      idProducto: map['id_producto'] as int,
      cantidad: map['cantidad'] as int,
    );
  }

  Map<String, Object?> toMap({bool withId = true}) {
    return {
      if (withId && id != null) 'id': id,
      'id_lista': idLista,
      'id_producto': idProducto,
      'cantidad': cantidad,
    };
  }

  ShoppingListItem copyWith({
    int? id,
    int? idLista,
    int? idProducto,
    int? cantidad,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      idLista: idLista ?? this.idLista,
      idProducto: idProducto ?? this.idProducto,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingListItem &&
        other.id == id &&
        other.idLista == idLista &&
        other.idProducto == idProducto &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, idLista, idProducto, cantidad);

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, idLista: $idLista, '
        'idProducto: $idProducto, cantidad: $cantidad)';
  }
}