import 'package:flutter_test/flutter_test.dart';
import 'package:travelai_flutter/models/place.dart';

// Hàm tìm kiếm giống hệt code trong app (main_dashboard.dart:233-246)
// Copy logic từ app để đảm bảo test đúng với code thật
List<Place> searchPlaces(String query, List<Place> allPlaces) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return [];
  return allPlaces.where((p) =>
    p.name.toLowerCase().contains(q) ||
    p.description.toLowerCase().contains(q) ||
    p.address.toLowerCase().contains(q)
  ).toList();
}

// Hàm lọc theo category giống code trong app (database_service.dart:122-129)
List<Place> filterByCategory(List<Place> places, int categoryId) {
  return places.where((p) => p.categoryId == categoryId).toList();
}

void main() {
  // Tạo danh sách địa điểm mẫu để test
  final samplePlaces = [
    Place(id: 1, categoryId: 1, name: 'Pho Bo Ha Noi',
        description: 'Mon ngon Ha Noi', address: 'Hoan Kiem, Ha Noi',
        latitude: 21.0, longitude: 105.0, imageUrl: '', ratingAvg: 4.5),
    Place(id: 2, categoryId: 1, name: 'Bun Bo Hue',
        description: 'Mon ngon mien Trung', address: 'TP Hue',
        latitude: 16.0, longitude: 107.0, imageUrl: '', ratingAvg: 4.3),
    Place(id: 3, categoryId: 2, name: 'Phong Nha Cave',
        description: 'Hang dong tu nhien', address: 'Quang Binh',
        latitude: 17.0, longitude: 106.0, imageUrl: '', ratingAvg: 4.8),
    Place(id: 4, categoryId: 3, name: 'Vinpearl Land Nha Trang',
        description: 'Khu vui choi giai tri', address: 'Nha Trang',
        latitude: 12.0, longitude: 109.0, imageUrl: '', ratingAvg: 4.2),
    Place(id: 5, categoryId: 4, name: 'Khach San 5 Sao',
        description: 'Khach san cao cap', address: 'Da Nang',
        latitude: 16.0, longitude: 108.0, imageUrl: '', ratingAvg: 4.6),
  ];

  group('Tim kiem dia diem theo tu khoa', () {
    test('Tim theo ten - tra ve dung 1 ket qua', () {
      final results = searchPlaces('Pho Bo', samplePlaces);
      expect(results.length, equals(1));
      expect(results.first.id, equals(1));
    });

    test('Tim theo mo ta - tra ve nhieu ket qua', () {
      final results = searchPlaces('mon ngon', samplePlaces);
      expect(results.length, equals(2));
      expect(results.map((p) => p.id), containsAll([1, 2]));
    });

    test('Tim theo dia chi', () {
      final results = searchPlaces('Quang Binh', samplePlaces);
      expect(results.length, equals(1));
      expect(results.first.id, equals(3));
    });

    test('Tim kiem khong phan biet chu hoa hay chu thuong', () {
      final r1 = searchPlaces('pho bo ha noi', samplePlaces);
      final r2 = searchPlaces('PHO BO HA NOI', samplePlaces);
      expect(r1.length, equals(1));
      expect(r2.length, equals(1));
      expect(r1.first.id, equals(r2.first.id));
    });

    test('Tim kiem voi query rong -> ket qua rong', () {
      expect(searchPlaces('', samplePlaces), isEmpty);
      expect(searchPlaces('   ', samplePlaces), isEmpty);
    });

    test('Tim kiem khong co ket qua', () {
      expect(searchPlaces('xyz123abc', samplePlaces), isEmpty);
    });

    test('Tim kiem theo tu khoa xuat hien o nhieu truong', () {
      // "Nha Trang" xuat hien trong name (Vinpearl Land Nha Trang)
      // va address (Nha Trang)
      final results = searchPlaces('Nha Trang', samplePlaces);
      expect(results.length, equals(1));
      expect(results.first.id, equals(4));
    });

    test('Tim kiem theo tu khoa co trong address', () {
      final results = searchPlaces('Da Nang', samplePlaces);
      expect(results.length, equals(1));
      expect(results.first.id, equals(5));
    });
  });

  group('Loc dia diem theo category', () {
    test('Loc category 1 (Am thuc) - tra ve 2 dia diem', () {
      final results = filterByCategory(samplePlaces, 1);
      expect(results.length, equals(2));
      expect(results.map((p) => p.id), containsAll([1, 2]));
    });

    test('Loc category khong co dia diem nao', () {
      final results = filterByCategory(samplePlaces, 99);
      expect(results, isEmpty);
    });

    test('Loc category 2 (Tham quan) - tra ve 1 dia diem', () {
      final results = filterByCategory(samplePlaces, 2);
      expect(results.length, equals(1));
      expect(results.first.id, equals(3));
    });
  });
}
