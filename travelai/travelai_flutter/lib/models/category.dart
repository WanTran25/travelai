class Category {
  final int id;
  final String name;
  final String icon;

  Category({required this.id, required this.name, required this.icon});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'icon': icon};

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int,
        name: map['name'] as String,
        icon: map['icon'] as String,
      );
}
