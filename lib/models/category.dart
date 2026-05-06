/// Define la clasificación de los activos financieros.
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  /// Mapea el DTO proveniente del [CategoryService].
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.parse(json['id'].toString()),
      name: (json['name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
