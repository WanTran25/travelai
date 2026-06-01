import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/place_card.dart';

IconData _getCategoryIcon(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return Icons.restaurant;
    case 'landmark':
      return Icons.location_on;
    case 'gamepad':
      return Icons.videogame_asset;
    case 'hotel':
      return Icons.hotel;
    case 'shopping_bag':
      return Icons.shopping_bag;
    default:
      return Icons.explore;
  }
}

class AiSuggestionTab extends StatefulWidget {
  final void Function(int placeId) onNavigateToDetail;

  const AiSuggestionTab({super.key, required this.onNavigateToDetail});

  @override
  State<AiSuggestionTab> createState() => _AiSuggestionTabState();
}

class _AiSuggestionTabState extends State<AiSuggestionTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final categories = provider.categories;
    final allPlaces = provider.allPlaces;
    final currentCategoryId = provider.selectedCategoryId;
    final aiSuggestions = provider.aiSuggestions;
    final aiSearching = provider.aiSearching;

    final showingSpots = aiSuggestions.isNotEmpty
        ? allPlaces.where((p) => aiSuggestions.containsKey(p.id)).toList()
        : currentCategoryId != null
            ? allPlaces.where((p) => p.categoryId == currentCategoryId).toList()
            : allPlaces;

    return Column(
      children: [
        // AI Search Card
        Card(
          color: AppColors.navyDark,
          elevation: 6,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accentOrange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Trí tuệ nhân tạo Gemini 3.5',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhập sở thích, mong muốn điểm đến của bạn ví dụ "Tôi thích thưởng thức hải sản ngon và check-in chụp hình ở bờ hồ dạo mát"',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ước mơ điểm đến...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.accentOrange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (aiSearching)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.accentOrange, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Gemini đang tính toán địa điểm đỉnh nhất...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = _searchController.text.trim();
                            if (text.isNotEmpty) {
                              provider.searchAI(text);
                            }
                          },
                          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: const Text(
                            'Gợi Ý Bằng AI',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (aiSuggestions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            provider.clearAiSuggestions();
                            _searchController.clear();
                          },
                          child: const Text('Xóa lọc AI', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (aiSuggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        color: AppColors.accentOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Text(
                          'AI SELECTED',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Gợi ý hành trình phù hợp nhất với bạn:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Khám phá theo danh mục',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: currentCategoryId == null,
                      onSelected: (_) => provider.selectedCategoryId = null,
                      selectedColor: AppColors.accentOrange,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: currentCategoryId == null ? Colors.white : Colors.grey,
                      ),
                    ),
                    ...categories.map((c) {
                      final isSelected = currentCategoryId == c.id;
                      return FilterChip(
                        label: Text(c.name),
                        selected: isSelected,
                        onSelected: (_) => provider.selectedCategoryId = c.id,
                        avatar: Icon(_getCategoryIcon(c.icon), size: 16),
                        selectedColor: AppColors.accentOrange,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (showingSpots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Không tìm thấy địa điểm phù hợp', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...showingSpots.map((spot) {
                  return PlaceCard(
                    place: spot,
                    aiReason: aiSuggestions[spot.id],
                    isFavorite: provider.favoritesList.contains(spot.id),
                    onFavoriteToggle: () => provider.toggleFavorite(spot.id),
                    onCardClick: () => widget.onNavigateToDetail(spot.id),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
