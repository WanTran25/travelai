class Favorite {
  final int userId;
  final int placeId;

  Favorite({required this.userId, required this.placeId});

  Map<String, dynamic> toMap() => {'userId': userId, 'placeId': placeId};

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
        userId: map['userId'] as int,
        placeId: map['placeId'] as int,
      );
}
