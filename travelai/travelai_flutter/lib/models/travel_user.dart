class TravelUser {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isActive;
  final String? avatar;
  final String? bio;
  final int? favoritesCount;
  final int? reviewsCount;

  TravelUser({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.isActive = true,
    this.avatar,
    this.bio,
    this.favoritesCount,
    this.reviewsCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_admin': isAdmin,
        'is_active': isActive,
        'avatar': avatar,
        'bio': bio,
      };

  factory TravelUser.fromJson(Map<String, dynamic> json) => TravelUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
        isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == null,
        avatar: json['avatar_url'] as String? ?? json['avatar'] as String?,
        bio: json['bio'] as String?,
        favoritesCount: json['favorites_count'] != null ? (json['favorites_count'] as num).toInt() : null,
        reviewsCount: json['reviews_count'] != null ? (json['reviews_count'] as num).toInt() : null,
      );
}
