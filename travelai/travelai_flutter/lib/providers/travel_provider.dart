import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/category.dart' as cat;
import '../models/place.dart';
import '../models/favorite.dart';
import '../models/review.dart';
import '../models/ai_log.dart';
import '../models/travel_user.dart';
import '../models/travel_suggestion.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';

class TravelProvider extends ChangeNotifier {
  TravelUser? _currentUser;
  List<cat.Category> _categories = [];
  List<Place> _allPlaces = [];
  int? _selectedCategoryId;
  List<int> _favoritesList = [];
  List<Review> _currentReviews = [];
  Map<int, String> _aiSuggestions = {};
  bool _aiSearching = false;
  bool _isOnline = false;

  TravelUser? get currentUser => _currentUser;
  List<cat.Category> get categories => _categories;
  List<Place> get allPlaces => _allPlaces;
  int? get selectedCategoryId => _selectedCategoryId;
  List<int> get favoritesList => _favoritesList;
  List<Review> get currentReviews => _currentReviews;
  Map<int, String> get aiSuggestions => _aiSuggestions;
  bool get aiSearching => _aiSearching;
  bool get isOnline => _isOnline;

  void updateCurrentUser(TravelUser user) {
    _currentUser = user;
    notifyListeners();
  }

  set selectedCategoryId(int? value) {
    _selectedCategoryId = value;
    notifyListeners();
  }

  Future<void> init() async {
    ApiService.onUnauthorized = () {
      _currentUser = null;
      _isOnline = false;
      notifyListeners();
    };

    await ApiService.init();
    _isOnline = await ApiService.isBackendAvailable();

    _currentUser = await ApiService.getSavedUser();
    if (_currentUser != null) {
      final userData = await ApiService.verifyToken();
      if (userData == null) {
        await ApiService.clearAuth();
        _currentUser = null;
        _isOnline = false;
      } else {
        _currentUser = TravelUser.fromJson(userData);
      }
    }
    notifyListeners();

    if (_currentUser != null) {
      await loadInitialData();
      await _loadFavorites();
    }
  }

  Future<void> loadInitialData() async {
    _categories = await ApiService.getCategories();
    _allPlaces = await ApiService.getPlaces();
    notifyListeners();
  }

  Future<bool> login(String email, String password,
      {String nameArg = 'Du khách'}) async {
    final user = await ApiService.login(email, password);
    if (user != null) {
      _currentUser = user;
      _isOnline = true;
      notifyListeners();
      await _loadFavorites();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    final user = await ApiService.register(name, email, password);
    if (user != null) {
      _currentUser = user;
      _isOnline = true;
      notifyListeners();
      await _loadFavorites();
      return true;
    }
    // Offline fallback
    _currentUser = TravelUser(id: 8881, name: name, email: email);
    _isOnline = false;
    notifyListeners();
    await _loadFavorites();
    return false;
  }

  Future<void> logout() async {
    await ApiService.logout();
    _currentUser = null;
    _aiSuggestions = {};
    _favoritesList = [];
    _isOnline = false;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_currentUser == null) return;

    if (_isOnline) {
      _favoritesList = await ApiService.getFavorites();
    } else {
      final favs = await DatabaseService.getFavoritesByUser(_currentUser!.id);
      _favoritesList = favs.map((f) => f.placeId).toList();
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(int placeId) async {
    final userId = _currentUser?.id;
    if (userId == null) return;

    final wasFav = _favoritesList.contains(placeId);

    if (_isOnline) {
      if (wasFav) {
        await ApiService.removeFavorite(placeId);
      } else {
        await ApiService.addFavorite(placeId);
      }
      await _loadFavorites();
    } else {
      if (wasFav) {
        await DatabaseService.deleteFavorite(userId, placeId);
      } else {
        await DatabaseService.insertFavorite(
            Favorite(userId: userId, placeId: placeId));
      }
      await _loadFavorites();
    }
    notifyListeners();
  }

  Future<void> loadReviewsForPlace(int placeId) async {
    if (_isOnline) {
      _currentReviews = await ApiService.getReviews(placeId);
    } else {
      _currentReviews = await DatabaseService.getReviewsForPlace(placeId);
    }
    notifyListeners();
  }

  Future<void> addReview(int placeId, int rating, String comment) async {
    final user = _currentUser;
    if (user == null) return;

    if (_isOnline) {
      await ApiService.addReview(placeId, rating, comment);
      await loadReviewsForPlace(placeId);
    } else {
      final review = Review(
        userId: user.id,
        placeId: placeId,
        userName: user.name,
        rating: rating,
        comment: comment,
      );
      await DatabaseService.insertReview(review);

      final updatedReviews = List<Review>.from(_currentReviews)..add(review);
      final avg = updatedReviews.map((r) => r.rating).fold<double>(0, (a, b) => a + b) /
          updatedReviews.length;
      final finalAvg = (avg * 10).roundToDouble() / 10.0;
      await DatabaseService.updatePlaceRating(placeId, finalAvg);

      await loadReviewsForPlace(placeId);
    }
  }

  Future<String?> searchAI(String prompt, {String? contextLocation}) async {
    final user = _currentUser;
    String? detectedLocation;

    // Always reload fresh data before AI query to pick up newly added places/categories
    if (_isOnline) {
      await loadInitialData();
    }

    if (_allPlaces.isEmpty) return null;

    _aiSearching = true;
    _aiSuggestions = {};
    notifyListeners();

    try {
      List<TravelSuggestion> suggestions;

      if (_isOnline) {
        final result = await ApiService.getAiSuggestions(prompt,
            contextLocation: contextLocation);
        suggestions = result.suggestions;
        detectedLocation = result.detectedLocation;
      } else {
        suggestions = await GeminiService.getSuggestions(
          userPrompt: prompt,
          places: _allPlaces,
          categories: _categories,
          apiKey: null,
        );
      }

      if (suggestions.isNotEmpty) {
        _aiSuggestions = {
          for (final s in suggestions) s.placeId: s.reason
        };
      }

      final suggestionsJson = jsonEncode(
        suggestions
            .map((s) => {'place_id': s.placeId, 'reason': s.reason})
            .toList(),
      );

      await DatabaseService.insertAiLog(AiLog(
        userId: user?.id,
        userPrompt: prompt,
        aiResponseJson: suggestionsJson,
      ));
    } catch (_) {
    } finally {
      _aiSearching = false;
      notifyListeners();
    }

    return detectedLocation;
  }

  void clearAiSuggestions() {
    _aiSuggestions = {};
    notifyListeners();
  }
}
