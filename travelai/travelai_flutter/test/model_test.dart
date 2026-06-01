import 'package:flutter_test/flutter_test.dart';
import 'package:travelai_flutter/models/place.dart';
import 'package:travelai_flutter/models/category.dart';
import 'package:travelai_flutter/models/travel_user.dart';
import 'package:travelai_flutter/models/review.dart';
import 'package:travelai_flutter/models/favorite.dart';

// File này test tất cả các model (kiểu dữ liệu) của app
// Các test này chỉ đơn thuần tạo object và kiểm tra serialize/deserialize

void main() {
  // ===================== PLACE =====================
  group('Place model', () {
    test('toMap va fromMap tra ve du lieu chinh xac', () {
      final place = Place(
        id: 1,
        categoryId: 2,
        name: 'Ho Hoan Kiem',
        description: 'Dep lam',
        address: 'Ha Noi',
        latitude: 21.0,
        longitude: 105.0,
        imageUrl: 'https://example.com/img.jpg',
        ratingAvg: 4.5,
      );

      final map = place.toMap();
      final restored = Place.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.categoryId, equals(2));
      expect(restored.name, equals('Ho Hoan Kiem'));
      expect(restored.description, equals('Dep lam'));
      expect(restored.address, equals('Ha Noi'));
      expect(restored.latitude, equals(21.0));
      expect(restored.longitude, equals(105.0));
      expect(restored.imageUrl, equals('https://example.com/img.jpg'));
      expect(restored.ratingAvg, equals(4.5));
    });

    test('toMap chua dung 9 truong bat buoc', () {
      final map = Place(
        id: 1, categoryId: 2, name: 'T', description: 'T',
        address: 'T', latitude: 0, longitude: 0,
        imageUrl: '', ratingAvg: 0,
      ).toMap();
      expect(map.length, equals(9));
      expect(map['id'], equals(1));
      expect(map['categoryId'], equals(2));
      expect(map['ratingAvg'], equals(0.0));
    });

    test('fromMap xu ly num thanh double cho latitude/longitude', () {
      final map = {
        'id': 1, 'categoryId': 1, 'name': 'X', 'description': 'X',
        'address': 'X', 'latitude': 10.5, 'longitude': 106.5,
        'imageUrl': '', 'ratingAvg': 4.0,
      };
      final place = Place.fromMap(map);
      expect(place.latitude, isA<double>());
      expect(place.longitude, isA<double>());
      expect(place.ratingAvg, isA<double>());
    });
  });

  // ===================== CATEGORY =====================
  group('Category model', () {
    test('toMap va fromMap tra ve du lieu chinh xac', () {
      final category = Category(id: 3, name: 'Am thuc', icon: 'restaurant');
      final map = category.toMap();
      final restored = Category.fromMap(map);

      expect(restored.id, equals(3));
      expect(restored.name, equals('Am thuc'));
      expect(restored.icon, equals('restaurant'));
      expect(map.length, equals(3));
    });
  });

  // ===================== TRAVEL USER =====================
  group('TravelUser model', () {
    test('toJson va fromJson tra ve du lieu chinh xac', () {
      final user = TravelUser(
        id: 1,
        name: 'Nguyen Van A',
        email: 'a@test.com',
        isAdmin: true,
        isActive: true,
        avatar: 'avatar.jpg',
        bio: 'Xin chao',
        favoritesCount: 5,
        reviewsCount: 3,
      );
      final json = user.toJson();
      final restored = TravelUser.fromJson(json);

      expect(restored.id, equals(1));
      expect(restored.name, equals('Nguyen Van A'));
      expect(restored.email, equals('a@test.com'));
      expect(restored.isAdmin, isTrue);
      expect(restored.isActive, isTrue);
      expect(restored.avatar, equals('avatar.jpg'));
      expect(restored.bio, equals('Xin chao'));
      expect(restored.favoritesCount, equals(5));
      expect(restored.reviewsCount, equals(3));
    });

    test('isAdmin mac dinh la false, isActive mac dinh la true', () {
      final user = TravelUser(id: 1, name: 'Test', email: 'test@test.com');
      expect(user.isAdmin, isFalse);
      expect(user.isActive, isTrue);
    });

    test('fromJson chap nhan is_admin = 1 (kieu int) nhu true', () {
      final user = TravelUser.fromJson({
        'id': 1, 'name': 'A', 'email': 'a@a.com',
        'is_admin': 1, 'is_active': 1,
      });
      expect(user.isAdmin, isTrue);
      expect(user.isActive, isTrue);
    });

    test('fromJson uu tien avatar_url hon avatar', () {
      final user = TravelUser.fromJson({
        'id': 1, 'name': 'A', 'email': 'a@a.com',
        'avatar_url': 'url1.jpg', 'avatar': 'url2.jpg',
      });
      expect(user.avatar, equals('url1.jpg'));
    });

    test('fromJson chap nhan avatar neu khong co avatar_url', () {
      final user = TravelUser.fromJson({
        'id': 1, 'name': 'A', 'email': 'a@a.com',
        'avatar': 'my_avatar.jpg',
      });
      expect(user.avatar, equals('my_avatar.jpg'));
    });

    test('fromJson xu ly favoritesCount va reviewsCount la null', () {
      final user = TravelUser.fromJson({
        'id': 1, 'name': 'A', 'email': 'a@a.com',
      });
      expect(user.favoritesCount, isNull);
      expect(user.reviewsCount, isNull);
    });
  });

  // ===================== REVIEW =====================
  group('Review model', () {
    test('toMap va fromMap tra ve du lieu chinh xac', () {
      final review = Review(
        id: 5, userId: 1, placeId: 10,
        userName: 'Nguyen Van A',
        rating: 4, comment: 'Dia diem dep',
        createdAt: 1000,
      );
      final map = review.toMap();
      final restored = Review.fromMap(map);

      expect(restored.id, equals(5));
      expect(restored.userId, equals(1));
      expect(restored.placeId, equals(10));
      expect(restored.userName, equals('Nguyen Van A'));
      expect(restored.rating, equals(4));
      expect(restored.comment, equals('Dia diem dep'));
      expect(restored.createdAt, equals(1000));
    });

    test('id mac dinh bang 0 neu khong cung cap', () {
      final review = Review(
        userId: 1, placeId: 1,
        userName: 'A', rating: 5, comment: 'OK',
      );
      expect(review.id, equals(0));
    });

    test('createdAt tu dong duoc tao bang thoi gian hien tai', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final review = Review(
        userId: 1, placeId: 1,
        userName: 'A', rating: 5, comment: 'OK',
      );
      expect(review.createdAt, greaterThanOrEqualTo(before));
    });

    test('fromMap chap nhan ca snake_case keys tu backend', () {
      final review = Review.fromMap({
        'id': 1, 'user_id': 2, 'place_id': 3,
        'user_name': 'A', 'rating': 4, 'comment': 'Good',
        'created_at': 12345,
      });
      expect(review.id, equals(1));
      expect(review.userId, equals(2));
      expect(review.placeId, equals(3));
      expect(review.userName, equals('A'));
    });

    test('fromMap xu ly reaction_counts va user_reaction', () {
      final review = Review.fromMap({
        'id': 1, 'userId': 1, 'placeId': 1,
        'userName': 'A', 'rating': 5, 'comment': 'Great',
        'reaction_counts': {'like': 5, 'love': 3, 'laugh': 1},
        'user_reaction': 'like',
      });
      expect(review.reactionCounts['like'], equals(5));
      expect(review.reactionCounts['love'], equals(3));
      expect(review.reactionCounts['laugh'], equals(1));
      expect(review.userReaction, equals('like'));
    });

    test('fromMap reaction_counts mac dinh la rong', () {
      final review = Review.fromMap({
        'id': 1, 'userId': 1, 'placeId': 1,
        'userName': 'A', 'rating': 5, 'comment': 'OK',
      });
      expect(review.reactionCounts, isEmpty);
      expect(review.userReaction, isNull);
    });
  });

  // ===================== FAVORITE =====================
  group('Favorite model', () {
    test('toMap va fromMap tra ve du lieu chinh xac', () {
      final fav = Favorite(userId: 1, placeId: 5);
      final map = fav.toMap();
      final restored = Favorite.fromMap(map);

      expect(restored.userId, equals(1));
      expect(restored.placeId, equals(5));
      expect(map.length, equals(2));
    });
  });
}
