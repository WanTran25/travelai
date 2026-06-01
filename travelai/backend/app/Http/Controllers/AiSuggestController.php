<?php

namespace App\Http\Controllers;

use App\Models\Place;
use App\Models\AiSuggestionsLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AiSuggestController extends Controller
{
    public function suggest(Request $request)
    {
        $request->validate([
            'prompt' => 'required|string',
        ]);

        $userPrompt = $request->prompt;
        $user = $request->user();
        $contextLocation = $request->input('context_location');

        $allPlaces = Place::with('category')->get();
        $keywords = $this->extractKeywords($userPrompt);

        // Use context_location if current query has no location
        if (empty($keywords['location']) && !empty($contextLocation)) {
            $keywords['location'] = $contextLocation;
        }

        // Step 1: Find keyword-based matches (deterministic, no AI)
        $matched = $this->findKeywordMatches($keywords, $allPlaces);

        // Limit to max 5 results
        $matched = array_slice($matched, 0, 5);

        // Step 2: If keyword matches found
        if (!empty($matched)) {
            $apiKey = env('GEMINI_API_KEY');
            $useGemini = !empty($apiKey) && $apiKey !== 'MY_GEMINI_API_KEY';

            if ($useGemini) {
                $matched = $this->enrichReasonsWithGemini($matched, $allPlaces, $userPrompt, $apiKey);
            } else {
                $matched = $this->buildReasons($matched, $keywords);
            }

            $response = [
                'suggestions' => $matched,
                'detected_location' => $keywords['location'],
            ];

            AiSuggestionsLog::create([
                'user_id' => $user ? $user->id : null,
                'user_prompt' => $userPrompt,
                'ai_response' => $response,
            ]);

            return response()->json($response);
        }

        // Step 3: No keyword matches → try Gemini for semantic understanding
        $apiKey = env('GEMINI_API_KEY');
        if (!empty($apiKey) && $apiKey !== 'MY_GEMINI_API_KEY') {
            return $this->semanticSearch($userPrompt, $allPlaces, $apiKey, $user, $keywords['location']);
        }

        // Step 4: No API key → return top-rated as fallback (max 5)
        $fallback = $this->topRatedFallback($allPlaces, $keywords['location']);
        $response = [
            'suggestions' => $fallback,
            'detected_location' => $keywords['location'],
        ];

        AiSuggestionsLog::create([
            'user_id' => $user ? $user->id : null,
            'user_prompt' => $userPrompt,
            'ai_response' => $response,
        ]);

        return response()->json($response);
    }

    /**
     * Vietnamese province/city names for location filtering
     */
    private $vietnamLocations = [
        // 3-word+ provinces / cities / regions
        'thành phố hồ chí minh', 'tp hồ chí minh', 'hồ chí minh',
        'thừa thiên huế', 'buôn ma thuột',
        'đồng bằng sông cửu long', 'đồng bằng bắc bộ', 'đông nam bộ',
        'bắc trung bộ', 'nam trung bộ', 'tây nguyên', 'miền núi phía bắc',
        // All 63 provinces + municipalities (2-word)
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
        // District / town names (commonly referenced)
        'quy nhơn', 'tam kỳ', 'hội an', 'đồng hới', 'đà lạt', 'nha trang',
        'phan rang', 'phan thiết', 'vũng tàu', 'biên hòa', 'thủ dầu một',
        'rạch giá', 'hà tiên', 'mỹ tho', 'bến lức', 'tân an',
        'tuy hòa', 'buôn hồ', 'pleiku', 'bảo lộc', 'long khánh',
        'cẩm phả', 'uông bí', 'móng cái', 'sầm sơn', 'cửa lò',
        'hồng lĩnh', 'đông hà', 'sơn tây', 'từ sơn', 'chí linh',
        'phủ lý', 'thái bình', 'tam điệp', 'bỉm sơn',
        // Single-word provinces and common names
        'sài gòn', 'saigon', 'huế', 'sapa', 'sa pa', 'hạ long',
        'mũi né', 'phú quốc', 'côn đảo', 'cát bà',
        // Regions
        'miền bắc', 'miền trung', 'miền nam', 'bắc bộ', 'trung bộ', 'nam bộ',
    ];

    /**
     * Split user prompt into keywords (2/3/4-word phrases + single words)
     * and detect location mentions
     */
    private function extractKeywords($prompt)
    {
        $stopWords = ['tôi', 'của', 'và', 'là', 'có', 'ở', 'với', 'cho', 'các', 'một', 'những',
                      'thì', 'mà', 'để', 'ra', 'lên', 'xuống', 'vào', 'đi', 'được', 'nên',
                      'muốn', 'không', 'cái', 'gì', 'nào', 'đây', 'đó', 'ấy', 'này',
                      'bạn', 'anh', 'chị', 'em', 'chúng', 'ta', 'người', 'khi', 'đang',
                      'sẽ', 'đã', 'rất', 'lắm', 'quá', 'hãy', 'xin', 'ơi', 'ạ', 'nhé',
                      'gợi', 'ý', 'cho', 'tiệm'];

        $rawWords = preg_split('/[\s,\.\?!:;\-]+/u', mb_strtolower($prompt, 'UTF-8'));
        $words = array_values(array_filter($rawWords, function ($w) {
            return mb_strlen($w, 'UTF-8') >= 2;
        }));

        // Generate 2-word, 3-word, 4-word phrases
        $phrases = [];
        $maxNgram = 4;
        for ($n = 2; $n <= $maxNgram && $n <= count($words); $n++) {
            for ($i = 0; $i <= count($words) - $n; $i++) {
                $parts = array_slice($words, $i, $n);
                $phrases[] = implode(' ', $parts);
            }
        }

        // Filter out stop words from single keywords
        $filteredWords = array_values(array_filter($words, function ($w) use ($stopWords) {
            return !in_array($w, $stopWords);
        }));

        // If all words were stop words, keep originals
        if (empty($filteredWords)) {
            $filteredWords = $words;
        }

        // Detect location: check longest phrases first (4-word → 3-word → 2-word → 1-word)
        $location = null;
        $sortedPhrases = $phrases;
        usort($sortedPhrases, function ($a, $b) {
            return count(explode(' ', $b)) <=> count(explode(' ', $a));
        });
        foreach ($sortedPhrases as $phrase) {
            if (in_array($phrase, $this->vietnamLocations)) {
                $location = $phrase;
                break;
            }
        }
        if (!$location) {
            foreach ($filteredWords as $word) {
                if (in_array($word, $this->vietnamLocations)) {
                    $location = $word;
                    break;
                }
            }
        }

        return [
            'phrases' => $phrases,
            'words' => $filteredWords,
            'location' => $location,
        ];
    }

    /**
     * Find places where any keyword appears in name, description, or address.
     * If a location is mentioned in the query, only include places in that location.
     */
    private function findKeywordMatches($keywords, $places)
    {
        $matched = [];
        $hasLocation = !empty($keywords['location']);

        foreach ($places as $place) {
            $name = mb_strtolower($place->name, 'UTF-8');
            $desc = mb_strtolower($place->description ?? '', 'UTF-8');
            $addr = mb_strtolower($place->address ?? '', 'UTF-8');

            // LOCATION FILTER: if query has a location, skip places not in that location
            if ($hasLocation) {
                $loc = $keywords['location'];
                $inLocation = str_contains($addr, $loc)
                    || str_contains($name, $loc)
                    || str_contains($desc, $loc);
                if (!$inLocation) {
                    continue;
                }
            }

            $matchedFields = [];
            $matchedKeywords = [];

            // Check 2-word phrases first (higher priority)
            foreach ($keywords['phrases'] as $phrase) {
                if ($this->alreadyMatched($matchedKeywords, $phrase)) continue;
                if (str_contains($name, $phrase)) {
                    $matchedFields[] = 'tên';
                    $matchedKeywords[] = $phrase;
                } elseif (str_contains($desc, $phrase)) {
                    $matchedFields[] = 'mô tả';
                    $matchedKeywords[] = $phrase;
                } elseif (str_contains($addr, $phrase)) {
                    $matchedFields[] = 'địa chỉ';
                    $matchedKeywords[] = $phrase;
                }
            }

            // Then check single words
            foreach ($keywords['words'] as $word) {
                if ($this->alreadyMatched($matchedKeywords, $word)) continue;
                if (str_contains($name, $word)) {
                    $matchedFields[] = 'tên';
                    $matchedKeywords[] = $word;
                } elseif (str_contains($desc, $word)) {
                    $matchedFields[] = 'mô tả';
                    $matchedKeywords[] = $word;
                } elseif (str_contains($addr, $word)) {
                    $matchedFields[] = 'địa chỉ';
                    $matchedKeywords[] = $word;
                }
            }

            if (!empty($matchedKeywords)) {
                $matched[] = [
                    'place' => $place,
                    'keywords' => array_unique($matchedKeywords),
                    'fields' => array_unique($matchedFields),
                    'score' => count($matchedKeywords),
                ];
            }
        }

        // Sort by number of keyword matches descending
        usort($matched, function ($a, $b) {
            return $b['score'] <=> $a['score'];
        });

        return $matched;
    }

    private function alreadyMatched($matched, $keyword)
    {
        foreach ($matched as $m) {
            if (str_contains($m, $keyword) || str_contains($keyword, $m)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Auto-generate reasons without AI
     */
    private function buildReasons($matched, $keywords)
    {
        $suggestions = [];
        foreach ($matched as $item) {
            $place = $item['place'];
            $kwStr = implode(', ', $item['keywords']);
            $fields = implode(', ', $item['fields']);
            $suggestions[] = [
                'place_id' => $place->id,
                'reason' => "{$place->name} (danh mục: {$place->category->name}) - chứa từ khoá '{$kwStr}' trong {$fields}.",
            ];
        }
        return $suggestions;
    }

    /**
     * Use Gemini to write better reasons for pre-matched places
     */
    private function enrichReasonsWithGemini($matched, $allPlaces, $userPrompt, $apiKey)
    {
        $matchedIds = collect($matched)->pluck('place.id')->toArray();
        $matchedData = $allPlaces->whereIn('id', $matchedIds)->map(function ($p) {
            return "ID:{$p->id}, Tên:{$p->name}, Mô tả:{$p->description}, Địa chỉ:{$p->address}, Danh mục:{$p->category->name}";
        })->values()->toArray();

        $systemInstruction = "Bạn là trợ lý du lịch TravelAI. Người dùng đã hỏi và hệ thống đã tìm ra những địa điểm phù hợp. Nhiệm vụ của bạn: viết một câu giải thích ngắn gọn cho mỗi địa điểm, giải thích tại sao nó phù hợp với yêu cầu của người dùng dựa trên tên, mô tả và vị trí. TRẢ VỀ JSON: {\"suggestions\": [{\"place_id\": 1, \"reason\": \"...\"}]}";

        $userPromptText = "Yêu cầu người dùng: \"{$userPrompt}\"\n\nCác địa điểm phù hợp:\n" . implode("\n", $matchedData) . "\n\nHãy viết reason cho mỗi địa điểm.";

        try {
            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}", [
                'system_instruction' => ['parts' => [['text' => $systemInstruction]]],
                'contents' => [['role' => 'user', 'parts' => [['text' => $userPromptText]]]],
                'generationConfig' => ['responseMimeType' => 'application/json', 'temperature' => 0.0],
            ]);

            $body = $response->json();
            $jsonText = $body['candidates'][0]['content']['parts'][0]['text'] ?? null;

            if ($jsonText) {
                $jsonText = trim(preg_replace('/^```json\s*|\s*```$/', '', $jsonText));
                $data = json_decode($jsonText, true);
                if (isset($data['suggestions'])) {
                    return $data['suggestions'];
                }
            }
        } catch (\Exception $e) {
            // Fallback to auto-generated reasons
        }

        return $this->buildReasons($matched, $this->extractKeywords($userPrompt));
    }

    /**
     * Gemini semantic search when no keyword matches
     */
    private function semanticSearch($userPrompt, $allPlaces, $apiKey, $user, $location = null)
    {
        // Filter by location if set
        $filtered = $allPlaces;
        if ($location) {
            $filtered = $filtered->filter(function ($p) use ($location) {
                $loc = mb_strtolower($location, 'UTF-8');
                return str_contains(mb_strtolower($p->address ?? '', 'UTF-8'), $loc)
                    || str_contains(mb_strtolower($p->name, 'UTF-8'), $loc)
                    || str_contains(mb_strtolower($p->description ?? '', 'UTF-8'), $loc);
            });
        }

        if ($filtered->isEmpty()) {
            $response = ['suggestions' => []];
            if ($location) $response['detected_location'] = $location;

            AiSuggestionsLog::create([
                'user_id' => $user ? $user->id : null,
                'user_prompt' => $userPrompt,
                'ai_response' => $response,
            ]);
            return response()->json($response);
        }

        $placesData = $filtered->map(function ($p) {
            return "ID:{$p->id}, Tên:{$p->name}, Mô tả:{$p->description}, Địa chỉ:{$p->address}, Danh mục:{$p->category->name}";
        })->values()->toArray();

        $systemInstruction = "Bạn là trợ lý du lịch TravelAI. Người dùng đưa ra yêu cầu. Hãy đọc kỹ tên, mô tả và địa chỉ của từng địa điểm. Chọn tối đa 5 địa điểm có nội dung liên quan đến yêu cầu. Trả về JSON: {\"suggestions\": [{\"place_id\": 1, \"reason\": \"...\"}]}. Nếu không có địa điểm nào phù hợp, trả về {\"suggestions\": []}.";

        $userPromptText = "Yêu cầu: \"{$userPrompt}\"\n\nDanh sách địa điểm:\n" . implode("\n", $placesData) . "\n\nChọn tối đa 5 địa điểm phù hợp và giải thích. Nếu không có, trả về [].";

        try {
            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}", [
                'system_instruction' => ['parts' => [['text' => $systemInstruction]]],
                'contents' => [['role' => 'user', 'parts' => [['text' => $userPromptText]]]],
                'generationConfig' => ['responseMimeType' => 'application/json', 'temperature' => 0.0],
            ]);

            $body = $response->json();
            $jsonText = $body['candidates'][0]['content']['parts'][0]['text'] ?? null;

            if ($jsonText) {
                $jsonText = trim(preg_replace('/^```json\s*|\s*```$/', '', $jsonText));
                $data = json_decode($jsonText, true);

                $data['detected_location'] = $location;

                AiSuggestionsLog::create([
                    'user_id' => $user ? $user->id : null,
                    'user_prompt' => $userPrompt,
                    'ai_response' => $data,
                ]);

                return response()->json($data);
            }
        } catch (\Exception $e) {
            // Fallback
        }

        // Ultimate fallback
        $fallback = $this->topRatedFallback($filtered);
        $response = ['suggestions' => $fallback];
        if ($location) $response['detected_location'] = $location;

        AiSuggestionsLog::create([
            'user_id' => $user ? $user->id : null,
            'user_prompt' => $userPrompt,
            'ai_response' => $response,
        ]);

        return response()->json($response);
    }

    /**
     * Return top-rated places as fallback (max 5, filtered by location if set)
     */
    private function topRatedFallback($places, $location = null)
    {
        $filtered = $places;
        if ($location) {
            $loc = mb_strtolower($location, 'UTF-8');
            $filtered = $filtered->filter(function ($p) use ($loc) {
                return str_contains(mb_strtolower($p->address ?? '', 'UTF-8'), $loc)
                    || str_contains(mb_strtolower($p->name, 'UTF-8'), $loc)
                    || str_contains(mb_strtolower($p->description ?? '', 'UTF-8'), $loc);
            });
        }

        if ($filtered->isEmpty()) {
            return [];
        }

        $sorted = $filtered->sortByDesc('rating_avg')->take(5);
        $result = [];
        foreach ($sorted as $place) {
            $result[] = [
                'place_id' => $place->id,
                'reason' => "{$place->name} ({$place->category->name})" . ($place->rating_avg > 0 ? " - {$place->rating_avg}★" : '') . " là địa điểm nổi bật.",
            ];
        }
        return $result;
    }
}
