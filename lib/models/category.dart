/// Clase que representa una categoría de inversión.
///
/// Permite clasificar los activos financieros (ej. Acciones, Criptos).
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  /// Crea una instancia de [Category] a partir de un mapa JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
    );
  }

  /// Convierte la instancia actual en un mapa compatible con JSON.
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
