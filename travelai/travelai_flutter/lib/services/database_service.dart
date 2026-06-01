import 'package:sembast/sembast.dart';
import 'database_factory.dart';
import '../models/category.dart' as cat;
import '../models/place.dart';
import '../models/favorite.dart';
import '../models/review.dart';
import '../models/ai_log.dart';

class DatabaseService {
  static Database? _database;

  static StoreRef<int, Map<String, dynamic>> _store(String name) =>
      intMapStoreFactory.store(name);

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = await dbPath;
    final db = await databaseFactory.openDatabase(path);

    final count = await _store('categories').count(db);
    if (count == 0) {
      await _seedData(db);
    }
    return db;
  }

  static Future<void> _seedData(Database db) async {
    await db.transaction((txn) async {
      final catStore = _store('categories');
      final placeStore = _store('places');
      final reviewStore = _store('reviews');

      await catStore.add(txn, {'id': 1, 'name': 'Ẩm thực', 'icon': 'restaurant'});
      await catStore.add(txn, {'id': 2, 'name': 'Tham quan', 'icon': 'landmark'});
      await catStore.add(txn, {'id': 3, 'name': 'Giải trí', 'icon': 'gamepad'});
      await catStore.add(txn, {'id': 4, 'name': 'Lưu trú', 'icon': 'hotel'});
      await catStore.add(txn, {'id': 5, 'name': 'Mua sắm', 'icon': 'shopping_bag'});

      await placeStore.add(txn, {
        'id': 1, 'categoryId': 2, 'name': 'Hồ Hoàn Kiếm',
        'description': 'Trái tim xanh của thủ đô Hà Nội, phong cảnh thơ mộng gắn liền với tháp Rùa cổ kính và cầu Thê Húc đỏ rực, thích hợp đi dạo, ngắm cảnh tinh khôi mỗi sớm mai.',
        'address': 'Phố Đinh Tiên Hoàng, Hàng Trống, Hoàn Kiếm, Hà Nội',
        'latitude': 21.028511, 'longitude': 105.852441,
        'imageUrl': 'https://images.unsplash.com/photo-1549693578-d683be217e58',
        'ratingAvg': 4.8,
      });
      await placeStore.add(txn, {
        'id': 2, 'categoryId': 1, 'name': 'Chợ Bến Thành',
        'description': 'Biểu tượng giao thương sầm uất lâu đời của Sài Gòn. Nơi hội tụ các gian hàng đồ thủ công mỹ nghệ tinh xảo cùng khu ẩm thực khổng lồ đa dạng các món ăn Nam Bộ.',
        'address': 'Đường Lê Lợi, Bến Thành, Quận 1, TP. Hồ Chí Minh',
        'latitude': 10.772535, 'longitude': 106.698031,
        'imageUrl': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1',
        'ratingAvg': 4.5,
      });
      await placeStore.add(txn, {
        'id': 3, 'categoryId': 2, 'name': 'Nhà Thờ Đức Bà',
        'description': 'Công trình kiến trúc vĩ đại mang đậm dấu ấn phong cách Romanesque phối hợp Gothic Pháp cổ tuyệt mĩ, một biểu tượng văn hóa tôn giáo và điểm check-in di sản.',
        'address': '01 Công xã Paris, Bến Ngé, Quận 1, TP. Hồ Chí Minh',
        'latitude': 10.779836, 'longitude': 106.699042,
        'imageUrl': 'https://images.unsplash.com/photo-1583417319070-4a69db38a482',
        'ratingAvg': 4.6,
      });
      await placeStore.add(txn, {
        'id': 4, 'categoryId': 2, 'name': 'Phố Cổ Hội An',
        'description': 'Di sản văn hóa thế giới bình yên lưu giữ dấu ấn thời gian với từng mái ngói rêu phong, gạch ngói vàng cổ cùng lễ hội thả đèn hoa đăng lấp lánh ban đêm trên sông Hoài thơ mộng.',
        'address': 'Minh An, Hội An, Quảng Nam',
        'latitude': 15.877085, 'longitude': 108.327421,
        'imageUrl': 'https://images.unsplash.com/photo-1528127269322-539801943592',
        'ratingAvg': 4.9,
      });
      await placeStore.add(txn, {
        'id': 5, 'categoryId': 5, 'name': 'Phố Đi Bộ Nguyễn Huệ',
        'description': 'Đại lộ đi bộ hoành tráng sầm uất nhất cả nước. Địa chỉ lý tưởng để đi bộ dạo mát vui tươi, chụp ảnh lưu niệm náo nhiệt và thưởng thức ẩm thực trà sữa độc đáo.',
        'address': 'Đường Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
        'latitude': 10.774577, 'longitude': 106.703215,
        'imageUrl': 'https://images.unsplash.com/photo-1549490349-8643362247b5',
        'ratingAvg': 4.7,
      });

      await reviewStore.add(txn, {
        'userId': 9991, 'placeId': 1, 'userName': 'Nguyễn Minh Tuấn',
        'rating': 5, 'comment': 'Địa điểm tuyệt vời để thư giãn cuối tuần! Không khí dạo mát quanh hồ gươm cực kỳ dễ chịu.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      await reviewStore.add(txn, {
        'userId': 9992, 'placeId': 2, 'userName': 'Trần Thị Lan',
        'rating': 4, 'comment': 'Ẩm thực chợ Bến Thành ngon và phong phú vô cùng, rất nhiều khách du lịch ghé thăm.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      await reviewStore.add(txn, {
        'userId': 9993, 'placeId': 4, 'userName': 'Lê Hoàng Nam',
        'rating': 5, 'comment': 'Hội An đẹp ngỡ ngàng về đêm, đi thuyền thả đèn hoa đăng cực thơ mộng và lãng mạn.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  // --- Categories ---

  static Future<List<cat.Category>> getCategories() async {
    final db = await database;
    final records = await _store('categories').find(db);
    return records.map((r) {
      final v = r.value;
      return cat.Category(id: v['id'] as int, name: v['name'] as String, icon: v['icon'] as String);
    }).toList();
  }

  // --- Places ---

  static Future<List<Place>> getAllPlaces() async {
    final db = await database;
    final records = await _store('places').find(db);
    return records.map((r) => Place.fromMap(r.value)).toList();
  }

  static Future<List<Place>> getPlacesByCategory(int categoryId) async {
    final db = await database;
    final records = await _store('places').find(
      db,
      finder: Finder(filter: Filter.equals('categoryId', categoryId)),
    );
    return records.map((r) => Place.fromMap(r.value)).toList();
  }

  static Future<Place?> getPlaceById(int id) async {
    final db = await database;
    final records = await _store('places').find(
      db,
      finder: Finder(filter: Filter.equals('id', id)),
    );
    if (records.isEmpty) return null;
    return Place.fromMap(records.first.value);
  }

  static Future<void> updatePlaceRating(int id, double rating) async {
    final db = await database;
    final records = await _store('places').find(
      db,
      finder: Finder(filter: Filter.equals('id', id)),
    );
    for (final r in records) {
      final data = Map<String, dynamic>.from(r.value);
      data['ratingAvg'] = rating;
      await _store('places').update(db, data, finder: Finder(filter: Filter.byKey(r.key)));
    }
  }

  // --- Favorites ---

  static Future<List<Favorite>> getFavoritesByUser(int userId) async {
    final db = await database;
    final records = await _store('favorites').find(
      db,
      finder: Finder(filter: Filter.equals('userId', userId)),
    );
    return records.map((r) => Favorite.fromMap(r.value)).toList();
  }

  static Future<void> insertFavorite(Favorite fav) async {
    final db = await database;
    final existing = await _store('favorites').find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('userId', fav.userId),
          Filter.equals('placeId', fav.placeId),
        ]),
      ),
    );
    if (existing.isEmpty) {
      await _store('favorites').add(db, fav.toMap());
    }
  }

  static Future<void> deleteFavorite(int userId, int placeId) async {
    final db = await database;
    final records = await _store('favorites').find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('userId', userId),
          Filter.equals('placeId', placeId),
        ]),
      ),
    );
    for (final r in records) {
      await _store('favorites').delete(db, finder: Finder(filter: Filter.byKey(r.key)));
    }
  }

  static Future<bool> isFavorite(int userId, int placeId) async {
    final db = await database;
    final records = await _store('favorites').find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('userId', userId),
          Filter.equals('placeId', placeId),
        ]),
      ),
    );
    return records.isNotEmpty;
  }

  // --- Reviews ---

  static Future<List<Review>> getReviewsForPlace(int placeId) async {
    final db = await database;
    final records = await _store('reviews').find(
      db,
      finder: Finder(
        filter: Filter.equals('placeId', placeId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return records.map((r) => Review.fromMap(r.value)).toList();
  }

  static Future<void> insertReview(Review review) async {
    final db = await database;
    await _store('reviews').add(db, review.toMap());
  }

  // --- AI Logs ---

  static Future<List<AiLog>> getAllAiLogs() async {
    final db = await database;
    final records = await _store('aiLogs').find(
      db,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return records.map((r) => AiLog.fromMap(r.value)).toList();
  }

  static Future<void> insertAiLog(AiLog log) async {
    final db = await database;
    await _store('aiLogs').add(db, log.toMap());
  }
}
