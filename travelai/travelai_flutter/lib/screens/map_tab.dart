import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/place_card.dart';

class MapTab extends StatefulWidget {
  final void Function(int placeId) onNavigateToDetail;

  const MapTab({super.key, required this.onNavigateToDetail});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final allPlaces = provider.allPlaces;
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;

    // Always show top 10 highest-rated places, sorted by ratingAvg descending
    final sorted = List<Place>.from(allPlaces)
      ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    final displayPlaces = sorted.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          color: AppColors.navyDark,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map,
                      color: AppColors.accentOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản đồ OpenStreetMap',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                           fontSize: 14,
                        ),
                      ),
                      Text(
                        'Top ${displayPlaces.length} địa điểm đánh giá cao nhất',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: isPhone ? 220 : 280,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(16.0, 108.0),
                    initialZoom: 5.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.travelai.app',
                    ),
                    MarkerLayer(
                      markers: allPlaces.map((spot) {
                        return Marker(
                          point: LatLng(spot.latitude, spot.longitude),
                          width: 28,
                          height: 28,
                          child: GestureDetector(
                            onTap: () {
                              widget.onNavigateToDetail(spot.id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.markerColor(
                                    spot.categoryId),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(76),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.place,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(6),
                    child: const Text(
                      'Kéo/zoom - chạm marker để xem',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        _mapController.move(
                          const LatLng(16.0, 108.0),
                          5.5,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Section title
        Row(
          children: [
            Text(
              'Tất cả địa điểm',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${displayPlaces.length}',
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Place cards list
        ...displayPlaces.map((spot) => PlaceCard(
              place: spot,
              aiReason: null,
              isFavorite: provider.favoritesList.contains(spot.id),
              onFavoriteToggle: () => provider.toggleFavorite(spot.id),
              onCardClick: () => widget.onNavigateToDetail(spot.id),
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}
