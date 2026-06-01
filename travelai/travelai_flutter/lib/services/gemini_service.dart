import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart' as cat;
import '../models/place.dart';
import '../models/travel_suggestion.dart';

class GeminiService {
  static Future<List<TravelSuggestion>> getSuggestions({
    required String userPrompt,
    required List<Place> places,
    List<cat.Category>? categories,
    String? apiKey,
  }) async {
    // Step 1: Extract keywords and find matches (deterministic)
    final keywords = _extractKeywords(userPrompt);
    final matched = _findKeywordMatches(keywords, places);

    if (matched.isNotEmpty) {
      // If Gemini API key available, use it to write nice reasons
      if (apiKey != null && apiKey.isNotEmpty && apiKey != 'MY_GEMINI_API_KEY') {
        final enriched = await _enrichReasonsWithGemini(
            matched, places, userPrompt, apiKey, categories);
        if (enriched != null) return enriched;
      }
      // Otherwise auto-generate reasons
      return _buildReasons(matched, keywords);
    }

    // No keyword matches → try Gemini semantic search
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'MY_GEMINI_API_KEY') {
      final semantic = await _semanticSearch(userPrompt, places, apiKey, categories);
      if (semantic != null) return semantic;
    }

    // Fallback: top-rated
    return _topRatedFallback(places);
  }

  static const _vietnamLocations = [
    'thành phố hồ chí minh', 'tp hồ chí minh', 'hồ chí minh',
    'thừa thiên huế', 'buôn ma thuột',
    'đồng bằng sông cửu long', 'đồng bằng bắc bộ', 'đông nam bộ',
    'bắc trung bộ', 'nam trung bộ', 'tây nguyên', 'miền núi phía bắc',
    'hà nội', 'hải phòng', 'đà nẵng', 'cần thơ',
    'hà giang', 'cao bằng', 'lào cai', 'bắc kạn', 'lạng sơn',
    'tuyên quang', 'hà nam', 'nam định', 'thái bình', 'ninh bình',
    'thái nguyên', 'phú thọ', 'bắc giang', 'quảng ninh', 'bắc ninh',
    'vĩnh phúc', 'hải dương', 'hưng yên', 'hòa bình', 'lai châu',
    'điện biên', 'sơn la', 'yên bái',
    'thanh hóa', 'nghệ an', 'hà tĩnh', 'quảng bình', 'quảng trị',
    'quảng nam', 'quảng ngãi', 'bình định', 'phú yên', 'bình thuận',
    'khánh hòa', 'ninh thuận', 'bình dương', 'bình phước', 'đồng nai',
    'tây ninh', 'bà rịa vũng tàu', 'long an', 'đồng tháp', 'tiền giang',
    'hậu giang', 'vĩnh long', 'bến tre', 'trà vinh', 'sóc trăng',
    'bạc liêu', 'cà mau', 'kiên giang', 'an giang',
    'gia lai', 'kon tum', 'đắk lắk', 'đắk nông', 'lâm đồng',
    'quy nhơn', 'tam kỳ', 'hội an', 'đồng hới', 'đà lạt', 'nha trang',
    'phan rang', 'phan thiết', 'vũng tàu', 'biên hòa', 'thủ dầu một',
    'rạch giá', 'hà tiên', 'mỹ tho', 'bến lức', 'tân an',
    'tuy hòa', 'buôn hồ', 'pleiku', 'bảo lộc', 'long khánh',
    'cẩm phả', 'uông bí', 'móng cái', 'sầm sơn', 'cửa lò',
    'hồng lĩnh', 'đông hà', 'sơn tây', 'từ sơn', 'chí linh',
    'phủ lý', 'thái bình', 'tam điệp', 'bỉm sơn',
    'sài gòn', 'saigon', 'huế', 'sapa', 'sa pa', 'hạ long',
    'mũi né', 'phú quốc', 'côn đảo', 'cát bà',
    'miền bắc', 'miền trung', 'miền nam', 'bắc bộ', 'trung bộ', 'nam bộ',
  ];

  static _Keywords _extractKeywords(String prompt) {
    const stopWords = {
      'tôi', 'của', 'và', 'là', 'có', 'ở', 'với', 'cho', 'các', 'một', 'những',
      'thì', 'mà', 'để', 'ra', 'lên', 'xuống', 'vào', 'đi', 'được', 'nên',
      'muốn', 'không', 'cái', 'gì', 'nào', 'đây', 'đó', 'ấy', 'này',
      'bạn', 'anh', 'chị', 'em', 'chúng', 'ta', 'người', 'khi', 'đang',
      'sẽ', 'đã', 'rất', 'lắm', 'quá', 'hãy', 'xin', 'ơi', 'ạ', 'nhé',
      'gợi', 'ý', 'tiệm',
    };

    final raw = prompt.toLowerCase().split(RegExp(r'[\s,\.\?!:;\-]+'));
    final words = raw.where((w) => w.length >= 2).toList();

    // Generate 2-word, 3-word, 4-word phrases
    final phrases = <String>[];
    const maxNgram = 4;
    for (int n = 2; n <= maxNgram && n <= words.length; n++) {
      for (int i = 0; i <= words.length - n; i++) {
        phrases.add(words.sublist(i, i + n).join(' '));
      }
    }

    final filtered = words.where((w) => !stopWords.contains(w)).toList();
    final finalWords = filtered.isEmpty ? words : filtered;

    // Detect location: check longest phrases first
    String? location;
    final sorted = List<String>.from(phrases)
      ..sort((a, b) => b.split(' ').length.compareTo(a.split(' ').length));
    for (final p in sorted) {
      if (_vietnamLocations.contains(p)) { location = p; break; }
    }
    if (location == null) {
      for (final w in finalWords) {
        if (_vietnamLocations.contains(w)) { location = w; break; }
      }
    }

    return _Keywords(phrases: phrases, words: finalWords, location: location);
  }

  static List<_MatchResult> _findKeywordMatches(_Keywords keywords, List<Place> places) {
    final matched = <_MatchResult>[];
    final hasLocation = keywords.location != null;

    for (final place in places) {
      final name = place.name.toLowerCase();
      final desc = place.description.toLowerCase();
      final addr = place.address.toLowerCase();

      // LOCATION FILTER: if query has a location, skip places not in that location
      if (hasLocation) {
        final loc = keywords.location!;
        final inLocation = addr.contains(loc) || name.contains(loc) || desc.contains(loc);
        if (!inLocation) continue;
      }

      final matchedKeywords = <String>{};
      final matchedFields = <String>{};

      // Check 2-word phrases first
      for (final phrase in keywords.phrases) {
        if (_alreadyMatched(matchedKeywords, phrase)) continue;
        if (name.contains(phrase)) {
          matchedFields.add('tên');
          matchedKeywords.add(phrase);
        } else if (desc.contains(phrase)) {
          matchedFields.add('mô tả');
          matchedKeywords.add(phrase);
        } else if (addr.contains(phrase)) {
          matchedFields.add('địa chỉ');
          matchedKeywords.add(phrase);
        }
      }

      // Check single words
      for (final word in keywords.words) {
        if (_alreadyMatched(matchedKeywords, word)) continue;
        if (name.contains(word)) {
          matchedFields.add('tên');
          matchedKeywords.add(word);
        } else if (desc.contains(word)) {
          matchedFields.add('mô tả');
          matchedKeywords.add(word);
        } else if (addr.contains(word)) {
          matchedFields.add('địa chỉ');
          matchedKeywords.add(word);
        }
      }

      if (matchedKeywords.isNotEmpty) {
        matched.add(_MatchResult(
          place: place,
          keywords: matchedKeywords.toList(),
          fields: matchedFields.toList(),
          score: matchedKeywords.length,
        ));
      }
    }

    matched.sort((a, b) => b.score.compareTo(a.score));
    return matched;
  }

  static bool _alreadyMatched(Set<String> matched, String keyword) {
    for (final m in matched) {
      if (m.contains(keyword) || keyword.contains(m)) return true;
    }
    return false;
  }

  static List<TravelSuggestion> _buildReasons(
      List<_MatchResult> matched, _Keywords keywords) {
    return matched.map((m) {
      final kwStr = m.keywords.join(', ');
      final fields = m.fields.join(', ');
      return TravelSuggestion(
        placeId: m.place.id,
        reason:
            '${m.place.name} - chứa từ khoá "$kwStr" trong $fields.',
      );
    }).toList();
  }

  static Future<List<TravelSuggestion>?> _enrichReasonsWithGemini(
    List<_MatchResult> matched,
    List<Place> allPlaces,
    String userPrompt,
    String apiKey,
    List<cat.Category>? categories,
  ) async {
    final matchedIds = matched.map((m) => m.place.id).toSet();
    final catMap = <int, String>{};
    if (categories != null) {
      for (final c in categories) {
        catMap[c.id] = c.name;
      }
    }

    final lines = allPlaces
        .where((p) => matchedIds.contains(p.id))
        .map((p) =>
            'ID:${p.id}, Tên:${p.name}, Mô tả:${p.description}, Địa chỉ:${p.address}, Danh mục:${catMap[p.categoryId] ?? ''}')
        .toList();

    final systemInstruction = '''
Bạn là trợ lý du lịch TravelAI. Người dùng đã hỏi và hệ thống đã tìm ra những địa điểm phù hợp. Nhiệm vụ của bạn: viết một câu giải thích ngắn gọn cho mỗi địa điểm, giải thích tại sao nó phù hợp với yêu cầu của người dùng dựa trên tên, mô tả và vị trí. TRẢ VỀ JSON: {"suggestions": [{"place_id": 1, "reason": "..."}]}
''';

    final promptBody = 'Yêu cầu người dùng: "$userPrompt"\n\nCác địa điểm phù hợp:\n${lines.join('\n')}\n\nHãy viết reason cho mỗi địa điểm.';

    try {
      final response = await http
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'contents': [
                {'parts': [{'text': promptBody}]}
              ],
              'systemInstruction': {
                'parts': [{'text': systemInstruction}]
              },
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.0,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final resultJson = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = resultJson['candidates'] as List?;
        final text = candidates?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          var clean = text.trim();
          if (clean.startsWith('```json')) clean = clean.substring(7);
          if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
          clean = clean.trim();
          final data = jsonDecode(clean) as Map<String, dynamic>;
          final arr = data['suggestions'] as List?;
          if (arr != null) {
            return arr
                .map((e) => TravelSuggestion.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<List<TravelSuggestion>?> _semanticSearch(
    String userPrompt,
    List<Place> allPlaces,
    String apiKey,
    List<cat.Category>? categories,
  ) async {
    final catMap = <int, String>{};
    if (categories != null) {
      for (final c in categories) catMap[c.id] = c.name;
    }

    final lines = allPlaces
        .map((p) =>
            'ID:${p.id}, Tên:${p.name}, Mô tả:${p.description}, Địa chỉ:${p.address}, Danh mục:${catMap[p.categoryId] ?? ''}')
        .toList();

    final systemInstruction = '''
Bạn là trợ lý du lịch TravelAI. Người dùng đưa ra yêu cầu. Hãy đọc kỹ tên, mô tả và địa chỉ của từng địa điểm. Chọn địa điểm nào có nội dung liên quan đến yêu cầu. Trả về JSON: {"suggestions": [{"place_id": 1, "reason": "..."}]}. Nếu không có địa điểm nào phù hợp, trả về {"suggestions": []}.
''';

    final promptBody = 'Yêu cầu: "$userPrompt"\n\nDanh sách địa điểm:\n${lines.join('\n')}\n\nChọn địa điểm phù hợp và giải thích.';

    try {
      final response = await http
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'contents': [
                {'parts': [{'text': promptBody}]}
              ],
              'systemInstruction': {
                'parts': [{'text': systemInstruction}]
              },
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.0,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final resultJson = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = resultJson['candidates'] as List?;
        final text = candidates?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          var clean = text.trim();
          if (clean.startsWith('```json')) clean = clean.substring(7);
          if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
          clean = clean.trim();
          final data = jsonDecode(clean) as Map<String, dynamic>;
          final arr = data['suggestions'] as List?;
          if (arr != null) {
            return arr
                .map((e) => TravelSuggestion.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static List<TravelSuggestion> _topRatedFallback(List<Place> places) {
    final sorted = List<Place>.from(places)
      ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    return sorted
        .take(3)
        .map((p) => TravelSuggestion(
              placeId: p.id,
              reason:
                  '${p.name} là một trong những địa điểm nổi bật nhất, lý tưởng cho chuyến đi của bạn.',
            ))
        .toList();
  }
}

class _Keywords {
  final List<String> phrases;
  final List<String> words;
  final String? location;
  _Keywords({required this.phrases, required this.words, this.location});
}

class _MatchResult {
  final Place place;
  final List<String> keywords;
  final List<String> fields;
  final int score;
  _MatchResult({
    required this.place,
    required this.keywords,
    required this.fields,
    required this.score,
  });
}
