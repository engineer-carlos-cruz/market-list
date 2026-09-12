class ShoppingList {
  const ShoppingList({
    this.id,
    required this.tienda,
    required this.fecha,
  });

  final int? id;
  final String tienda;
  final DateTime fecha;

  factory ShoppingList.fromMap(Map<String, Object?> map) {
    return ShoppingList(
      id: map['id'] as int?,
      tienda: map['tienda'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Map<String, Object?> toMap({bool withId = true}) {
    return {
      if (withId && id != null) 'id': id,
      'tienda': tienda,
      'fecha': fecha.toIso8601String(),
    };
  }

  ShoppingList copyWith({
    int? id,
    String? tienda,
    DateTime? fecha,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      tienda: tienda ?? this.tienda,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList &&
        other.id == id &&
        other.tienda == tienda &&
        other.fecha == fecha;
  }

  @override
  int get hashCode => Object.hash(id, tienda, fecha);

  @override
  String toString() {
    return 'ShoppingList(id: $id, tienda: $tienda, fecha: $fecha)';
  }
}