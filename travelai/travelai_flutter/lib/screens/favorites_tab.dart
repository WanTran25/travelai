import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/proxied_image.dart';

class FavoritesTab extends StatelessWidget {
  final void Function(int placeId) onNavigateToDetail;

  const FavoritesTab({super.key, required this.onNavigateToDetail});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final allPlaces = provider.allPlaces;
    final favoritesList = provider.favoritesList;

    final favSpots =
        allPlaces.where((p) => favoritesList.contains(p.id)).toList();

    final isPhone = MediaQuery.of(context).size.shortestSide < 600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite,
                    color: Colors.red, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Yêu thích của tôi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                   fontSize: 20,
                ),
              ),
              if (favSpots.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${favSpots.length}',
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (favSpots.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chưa có địa điểm yêu thích nào.',
                        style: TextStyle(color: Colors.grey)),
                    Text('Nhấn vào trái tim để thêm vào đây.',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: isPhone
                  ? ListView.builder(
                      itemCount: favSpots.length,
                      itemBuilder: (context, index) {
                        final spot = favSpots[index];
                        return _buildFavCard(spot, provider, context);
                      },
                    )
                  : GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            2 + 1,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: favSpots.length,
                      itemBuilder: (context, index) {
                        final spot = favSpots[index];
                        return _buildFavCard(spot, provider, context);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavCard(
      dynamic spot, TravelProvider provider, BuildContext context) {
    return Card(
      color: AppColors.navyDark,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onNavigateToDetail(spot.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProxiedCachedImage(
                  imageUrl: spot.imageUrl,
                  width: MediaQuery.of(context).size.shortestSide < 600 ? 70 : 90,
                  height: MediaQuery.of(context).size.shortestSide < 600 ? 70 : 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(spot.address,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFD700), size: 12),
                        const SizedBox(width: 2),
                        Text('${spot.ratingAvg} ★',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    provider.toggleFavorite(spot.id),
                icon: const Icon(Icons.delete,
                    color: Colors.red, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
