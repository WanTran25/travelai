import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart' as cat;
import '../models/place.dart';
import '../models/review.dart';
import '../models/travel_user.dart';
import '../models/travel_suggestion.dart';
import 'database_service.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _defaultBaseUrl = 'http://localhost:8000/api';

  static String _baseUrl = _defaultBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  static String get baseUrl => _baseUrl;

  static String proxiedImageUrl(String url) {
    if (url.startsWith('http')) {
      try {
        final backendHost = Uri.parse(_baseUrl).host;
        final imageHost = Uri.parse(url).host;
        if (imageHost != backendHost) {
          return '$_baseUrl/image-proxy?url=${Uri.encodeComponent(url)}';
        }
      } catch (_) {
        return url;
      }
    }
    return url;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = TravelUser.fromJson(userData);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<TravelUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    try {
      return TravelUser.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static void Function()? onUnauthorized;

  static Future<Map<String, dynamic>?> verifyToken() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/user'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      await _checkUnauthorized(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> _checkUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      await clearAuth();
      onUnauthorized?.call();
    }
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // --- Auth ---

  static Future<TravelUser?> register(
      String name, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: _headers(null),
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveToken(data['access_token'] as String);
        final userData = data['user'] as Map<String, dynamic>;
        await _saveUser(userData);
        return TravelUser.fromJson(userData);
      }
    } catch (_) {}
    return null;
  }

  static Future<TravelUser?> login(String email, String password) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: _headers(null),
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveToken(data['access_token'] as String);
      final userData = data['user'] as Map<String, dynamic>;
      await _saveUser(userData);
      return TravelUser.fromJson(userData);
    }

    String? msg;
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.values.isNotEmpty) {
          final first = (errors.values.first as List?)?.first;
          if (first is String) msg = first;
        }
        if (msg == null) {
          final m = body['message'];
          if (m is String) msg = m;
        }
      }
    } catch (_) {}
    throw Exception(msg ?? 'Đăng nhập thất bại');
  }

  static Future<bool> logout() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/logout'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      await clearAuth();
      return response.statusCode == 200;
    } catch (_) {
      await clearAuth();
      return false;
    }
  }

  // --- Categories ---

  static Future<List<cat.Category>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories'), headers: _headers(null))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((e) => cat.Category.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return await DatabaseService.getCategories();
  }

  // --- Places ---

  static Future<List<Place>> getPlaces({int? categoryId}) async {
    try {
      var url = '$_baseUrl/places';
      if (categoryId != null) url += '?category_id=$categoryId';

      final response = await http
          .get(Uri.parse(url), headers: _headers(null))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => _parsePlace(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    if (categoryId != null) {
      return await DatabaseService.getPlacesByCategory(categoryId);
    }
    return await DatabaseService.getAllPlaces();
  }

  static Future<Place?> getPlaceById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/places/$id'), headers: _headers(null))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parsePlace(data);
      }
    } catch (_) {}
    return await DatabaseService.getPlaceById(id);
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Place _parsePlace(Map<String, dynamic> map) {
    final calcRating = map['calculated_rating_avg'];
    return Place(
      id: _toInt(map['id']),
      categoryId: _toInt(map['category_id']),
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      imageUrl: map['image_url'] as String? ?? '',
      ratingAvg: calcRating != null
          ? _toDouble(calcRating)
          : _toDouble(map['rating_avg']),
    );
  }

  // --- Favorites ---

  static Future<List<int>> getFavorites() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/favorites'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => (e['place_id'] ?? e['id']) as int).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Place>> getFavoritePlaces() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/favorites'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => _parsePlace(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addFavorite(int placeId) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/favorites/$placeId'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeFavorite(int placeId) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/favorites/$placeId'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Reviews ---

  static Future<List<Review>> getReviews(int placeId) async {
    try {
      final token = await getToken();
      final response = await http
          .get(Uri.parse('$_baseUrl/reviews/place/$placeId'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) {
          final m = e as Map<String, dynamic>;
          return Review(
            id: (m['id'] as num).toInt(),
            userId: (m['user_id'] as num).toInt(),
            placeId: (m['place_id'] as num).toInt(),
            userName: m['user'] != null
                ? (m['user'] as Map<String, dynamic>)['name'] as String
                : 'Unknown',
            userAvatar: m['user_avatar'] as String?,
            rating: (m['rating'] as num).toInt(),
            comment: m['comment'] as String,
            createdAt: m['created_at'] is String
                ? DateTime.parse(m['created_at'] as String).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            reactionCounts: m['reaction_counts'] != null
                ? (m['reaction_counts'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()))
                : {},
            userReaction: m['user_reaction'] as String?,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addReview(int placeId, int rating, String comment) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reviews'),
            headers: _headers(token),
            body: jsonEncode({
              'place_id': placeId,
              'rating': rating,
              'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // --- Review Reactions ---

  static Future<Map<String, dynamic>?> reactToReview(int reviewId, String reaction) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reviews/$reviewId/react'),
            headers: _headers(token),
            body: jsonEncode({'reaction': reaction}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // --- Profile ---

  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final token = await getToken();
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/profile/$userId'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    String? name,
    String? bio,
    String? avatar,
  }) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (bio != null) body['bio'] = bio;
      if (avatar != null) body['avatar'] = avatar;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/profile'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> uploadAvatarFile(XFile file) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'avatar_file', bytes,
        filename: file.name,
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // --- AI Suggestions ---

  static Future<({List<TravelSuggestion> suggestions, String? detectedLocation})>
      getAiSuggestions(String prompt, {String? contextLocation}) async {
    final token = await getToken();
    if (token == null) return (suggestions: <TravelSuggestion>[], detectedLocation: null);
    try {
      final body = <String, dynamic>{'prompt': prompt};
      if (contextLocation != null) {
        body['context_location'] = contextLocation;
      }
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/suggest'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestionsArr = data['suggestions'] as List?;
        final suggestions = suggestionsArr != null
            ? suggestionsArr
                .map((e) => TravelSuggestion.fromJson(e as Map<String, dynamic>))
                .toList()
            : <TravelSuggestion>[];
        final detectedLocation = data['detected_location'] as String?;
        return (suggestions: suggestions, detectedLocation: detectedLocation);
      }
    } catch (_) {}
    return (suggestions: <TravelSuggestion>[], detectedLocation: null);
  }

  // --- Health Check ---

  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ======================= ADMIN API =======================

  static Future<Map<String, dynamic>?> getAdminDashboard() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/dashboard'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      await _checkUnauthorized(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getAdminPlaces() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/places'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createAdminPlace(
      Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/admin/places'),
              headers: _headers(token), body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateAdminPlace(
      int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/admin/places/$id'),
              headers: _headers(token), body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteAdminPlace(int id) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/admin/places/$id'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getAdminCategories() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/categories'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createAdminCategory(
      Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/admin/categories'),
              headers: _headers(token), body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateAdminCategory(
      int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/admin/categories/$id'),
              headers: _headers(token), body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteAdminCategory(int id) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/admin/categories/$id'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getAdminUsers() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final response = await http
        .get(Uri.parse('$_baseUrl/admin/users'), headers: _headers(token))
        .timeout(const Duration(seconds: 15));
    await _checkUnauthorized(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('Lỗi server: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final response = await http
        .post(
          Uri.parse('$_baseUrl/admin/users'),
          headers: _headers(token),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'is_admin': isAdmin,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    final msg = body is Map ? (body['message'] ?? 'Lỗi server') : 'Lỗi server';
    throw Exception(msg);
  }

  static Future<void> toggleAdminUserActive(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final response = await http
        .post(Uri.parse('$_baseUrl/admin/users/$id/toggle-active'),
            headers: _headers(token))
        .timeout(const Duration(seconds: 10));
    await _checkUnauthorized(response);
    if (response.statusCode == 200) return;
    try {
      final body = jsonDecode(response.body);
      final msg = body is Map ? (body['message'] ?? 'Lỗi server') : 'Lỗi server';
      throw Exception(msg);
    } catch (_) {
      throw Exception('Lỗi server');
    }
  }

  static Future<void> toggleAdminUserAdmin(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final response = await http
        .post(Uri.parse('$_baseUrl/admin/users/$id/toggle-admin'),
            headers: _headers(token))
        .timeout(const Duration(seconds: 10));
    await _checkUnauthorized(response);
    if (response.statusCode == 200) return;
    try {
      final body = jsonDecode(response.body);
      final msg = body is Map ? (body['message'] ?? 'Lỗi server') : 'Lỗi server';
      throw Exception(msg);
    } catch (_) {
      throw Exception('Lỗi server');
    }
  }

  static Future<bool> deleteAdminUser(int id) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/admin/users/$id'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getAdminReviews() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/reviews'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteAdminReview(int id) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/admin/reviews/$id'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getAdminAiLogs() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/ai-logs'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
    } catch (_) {}
    return [];
  }

}
