import 'package:flutter_test/flutter_test.dart' hide Finder;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:travelai_flutter/models/place.dart';
import 'package:travelai_flutter/models/category.dart' as cat;
import 'package:travelai_flutter/models/favorite.dart';
import 'package:travelai_flutter/models/review.dart';

// Test các thao tác database local (giống DatabaseService trong app)
// Sử dụng Sembast in-memory để không cần file thật

StoreRef<int, Map<String, dynamic>> _store(String name) =>
    intMapStoreFactory.store(name);

DatabaseFactory get factory => databaseFactoryMemory;

Future<Database> createDb() => factory.openDatabase('test.db');

void main() {
  late Database db;

  setUp(() async {
    db = await createDb();
  });

  tearDown(() async {
    await db.close();
    await factory.deleteDatabase('test.db');
  });

  group('Categories CRUD', () {
    test('Them category va lay danh sach', () async {
      await _store('categories').add(db, {'id': 1, 'name': 'Am thuc', 'icon': 'restaurant'});
      await _store('categories').add(db, {'id': 2, 'name': 'Tham quan', 'icon': 'landmark'});

      final records = await _store('categories').find(db);
      expect(records.length, equals(2));
    });

    test('Chuyen tu record sang Category model', () async {
      await _store('categories').add(db, {'id': 3, 'name': 'Mua sam', 'icon': 'shopping_bag'});
      final records = await _store('categories').find(db);

      final categories = records.map((r) {
        final v = r.value;
        return cat.Category(id: v['id'] as int, name: v['name'] as String, icon: v['icon'] as String);
      }).toList();

      expect(categories.length, equals(1));
      expect(categories.first.id, equals(3));
      expect(categories.first.name, equals('Mua sam'));
      expect(categories.first.icon, equals('shopping_bag'));
    });
  });

  group('Places CRUD', () {
    test('Them place va lay danh sach', () async {
      await _store('places').add(db, {
        'id': 1, 'categoryId': 1, 'name': 'Ho Hoan Kiem',
        'description': 'Dep', 'address': 'Ha Noi',
        'latitude': 21.0, 'longitude': 105.0,
        'imageUrl': '', 'ratingAvg': 4.5,
      });

      final records = await _store('places').find(db);
      expect(records.length, equals(1));

      final place = Place.fromMap(records.first.value);
      expect(place.name, equals('Ho Hoan Kiem'));
      expect(place.ratingAvg, equals(4.5));
    });

    test('Loc place theo categoryId', () async {
      await _store('places').add(db, {'id': 1, 'categoryId': 1, 'name': 'A', 'description': 'A', 'address': 'A', 'latitude': 0.0, 'longitude': 0.0, 'imageUrl': '', 'ratingAvg': 4.0});
      await _store('places').add(db, {'id': 2, 'categoryId': 2, 'name': 'B', 'description': 'B', 'address': 'B', 'latitude': 0.0, 'longitude': 0.0, 'imageUrl': '', 'ratingAvg': 4.0});
      await _store('places').add(db, {'id': 3, 'categoryId': 1, 'name': 'C', 'description': 'C', 'address': 'C', 'latitude': 0.0, 'longitude': 0.0, 'imageUrl': '', 'ratingAvg': 4.0});

      final records = await _store('places').find(
        db,
        finder: Finder(filter: Filter.equals('categoryId', 1)),
      );
      expect(records.length, equals(2));
    });

    test('Cap nhat ratingAvg', () async {
      final key = await _store('places').add(db, {'id': 1, 'categoryId': 1, 'name': 'Test', 'description': 'Test', 'address': 'Test', 'latitude': 0.0, 'longitude': 0.0, 'imageUrl': '', 'ratingAvg': 3.0});

      final data = Map<String, dynamic>.from((await _store('places').record(key).get(db))!);
      data['ratingAvg'] = 4.5;
      await _store('places').update(db, data, finder: Finder(filter: Filter.byKey(key)));

      final updated = await _store('places').record(key).get(db);
      expect(updated!['ratingAvg'], equals(4.5));
    });
  });

  group('Favorites CRUD', () {
    test('Them favorite va kiem tra ton tai', () async {
      await _store('favorites').add(db, {'userId': 1, 'placeId': 5});

      final records = await _store('favorites').find(
        db,
        finder: Finder(filter: Filter.and([
          Filter.equals('userId', 1),
          Filter.equals('placeId', 5),
        ])),
      );
      expect(records.length, equals(1));
    });

    test('Xoa favorite', () async {
      await _store('favorites').add(db, {'userId': 1, 'placeId': 5});

      var records = await _store('favorites').find(
        db,
        finder: Finder(filter: Filter.and([
          Filter.equals('userId', 1),
          Filter.equals('placeId', 5),
        ])),
      );
      for (final r in records) {
        await _store('favorites').delete(db, finder: Finder(filter: Filter.byKey(r.key)));
      }

      final afterDelete = await _store('favorites').find(
        db,
        finder: Finder(filter: Filter.and([
          Filter.equals('userId', 1),
          Filter.equals('placeId', 5),
        ])),
      );
      expect(afterDelete, isEmpty);
    });

    test('Lay favorites cua mot user', () async {
      await _store('favorites').add(db, {'userId': 1, 'placeId': 1});
      await _store('favorites').add(db, {'userId': 1, 'placeId': 2});
      await _store('favorites').add(db, {'userId': 2, 'placeId': 3});

      final records = await _store('favorites').find(
        db,
        finder: Finder(filter: Filter.equals('userId', 1)),
      );
      expect(records.length, equals(2));
    });
  });

  group('Reviews CRUD', () {
    test('Them review va lay danh sach theo place', () async {
      await _store('reviews').add(db, {
        'userId': 1, 'placeId': 1, 'userName': 'A',
        'rating': 5, 'comment': 'Tuyet voi',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      final records = await _store('reviews').find(
        db,
        finder: Finder(filter: Filter.equals('placeId', 1)),
      );
      expect(records.length, equals(1));

      final review = Review.fromMap(records.first.value);
      expect(review.rating, equals(5));
      expect(review.comment, equals('Tuyet voi'));
    });

    test('Sap xep review theo thoi gian moi nhat truoc', () async {
      await _store('reviews').add(db, {
        'userId': 1, 'placeId': 1, 'userName': 'A',
        'rating': 4, 'comment': 'Cu',
        'createdAt': 1000,
      });
      await _store('reviews').add(db, {
        'userId': 2, 'placeId': 1, 'userName': 'B',
        'rating': 5, 'comment': 'Moi',
        'createdAt': 2000,
      });

      final records = await _store('reviews').find(
        db,
        finder: Finder(
          filter: Filter.equals('placeId', 1),
          sortOrders: [SortOrder('createdAt', false)],
        ),
      );
      expect(records.length, equals(2));
      expect(Review.fromMap(records.first.value).comment, equals('Moi'));
    });
  });
}
