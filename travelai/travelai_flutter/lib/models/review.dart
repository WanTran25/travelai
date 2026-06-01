class Review {
  final int id;
  final int userId;
  final int placeId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String comment;
  final int createdAt;
  final Map<String, int> reactionCounts;
  final String? userReaction;

  Review({
    this.id = 0,
    required this.userId,
    required this.placeId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    int? createdAt,
    this.reactionCounts = const {},
    this.userReaction,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'placeId': placeId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] as int? ?? 0,
        userId: map['userId'] as int? ?? map['user_id'] as int? ?? 0,
        placeId: map['placeId'] as int? ?? map['place_id'] as int? ?? 0,
        userName: map['userName'] as String? ?? map['user_name'] as String? ?? '',
        userAvatar: map['userAvatar'] as String? ?? map['user_avatar'] as String?,
        rating: map['rating'] as int? ?? 0,
        comment: map['comment'] as String? ?? '',
        createdAt: map['createdAt'] as int? ?? map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        reactionCounts: map['reaction_counts'] != null
            ? (map['reaction_counts'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()))
            : {},
        userReaction: map['user_reaction'] as String?,
      );
}
