class Category {
  final int id;
  final String name;
  final String slug;
  final String? createdAt;
  final String? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to convert JSON to Category
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        slug: json['slug'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

 Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
  get imageUrl => null;

  
}
