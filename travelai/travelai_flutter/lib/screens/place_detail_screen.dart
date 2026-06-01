import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/review_item.dart';
import '../widgets/write_review_dialog.dart';
import '../widgets/proxied_image.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _showReviewDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().loadReviewsForPlace(widget.placeId);
    });
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final place =
        provider.allPlaces.where((p) => p.id == widget.placeId).firstOrNull;
    final isFavorite = provider.favoritesList.contains(widget.placeId);
    final reviews = provider.currentReviews;
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;

    if (place == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.accentOrange)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(place.name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16.0)),
        backgroundColor: AppColors.navyDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => provider.toggleFavorite(widget.placeId),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ProxiedCachedImage(
            imageUrl: place.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: isPhone ? 240 : 320,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${place.ratingAvg}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Map section ---
                if (place.latitude != 0 && place.longitude != 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: isPhone ? 180 : 220,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter:
                                  LatLng(place.latitude, place.longitude),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.travelai.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                        place.latitude, place.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on,
                                        color: AppColors.accentOrange,
                                        size: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: ElevatedButton.icon(
                              onPressed: () => _openGoogleMaps(
                                  place.latitude, place.longitude),
                              icon: const Icon(Icons.navigation,
                                  size: 16, color: Colors.white),
                              label: const Text('Dẫn đường',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentOrange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Address ---
                Text('Vị trí địa chỉ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.accentOrange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(place.address,
                          style: const TextStyle(
                              color: Color(0xFFE3E4EB), fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Description ---
                Text('Giới thiệu điểm đến',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0)),
                const SizedBox(height: 6),
                Text(place.description,
                    style: const TextStyle(
                        color: Color(0xFFE3E4EB),
                        fontSize: 13,
                        height: 1.4)),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đánh giá từ du khách',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0)),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _showReviewDialog = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Viết Đánh Giá',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Chưa có đánh giá nào. Hãy là người đầu tiên chia sẻ cảm nghĩ!',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...reviews.map((r) => ReviewItem(review: r)),
        ],
      ),
      floatingActionButton: _showReviewDialog
          ? WriteReviewDialog(
              onDismiss: () =>
                  setState(() => _showReviewDialog = false),
              onSubmit: (rating, comment) {
                provider.addReview(widget.placeId, rating, comment);
                setState(() => _showReviewDialog = false);
              },
            )
          : null,
    );
  }
}
