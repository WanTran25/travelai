class Place {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  double ratingAvg;

  Place({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.ratingAvg,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'ratingAvg': ratingAvg,
      };

  factory Place.fromMap(Map<String, dynamic> map) => Place(
        id: map['id'] as int,
        categoryId: map['categoryId'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        address: map['address'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        imageUrl: map['imageUrl'] as String,
        ratingAvg: (map['ratingAvg'] as num).toDouble(),
      );
}
