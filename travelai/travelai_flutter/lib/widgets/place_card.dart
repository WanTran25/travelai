import 'package:flutter/material.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import 'proxied_image.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final String? aiReason;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCardClick;

  const PlaceCard({
    super.key,
    required this.place,
    this.aiReason,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onCardClick,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final imageHeight = isPhone ? 160.0 : 200.0;

    return Card(
      margin: EdgeInsets.only(
        bottom: isPhone ? 16 : 20,
      ),
      color: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      elevation: isPhone ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onCardClick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: Stack(
                children: [
                  ProxiedCachedImage(
                    imageUrl: place.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: imageHeight,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite ? Colors.red : AppColors.primaryText(context),
                          size: isPhone ? 22 : 26,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Text(
                      place.name,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(
                isPhone ? 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${place.ratingAvg}',
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          color: AppColors.secondaryText(context), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: TextStyle(
                            color: AppColors.secondaryText(context),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: isPhone ? 10.0 : 14.0),

                  Text(
                    place.description,
                    style: TextStyle(
                      color: AppColors.primaryText(context).withOpacity(0.85),
                      fontSize: 13,
                    ),
                    maxLines: isPhone ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (aiReason != null) ...[
                    SizedBox(
                        height: isPhone ? 12.0 : 16.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentOrange.withAlpha(76),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: AppColors.accentOrange,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'LÝ DO LỰA CHỌN TỪ TRAVELAI',
                                style: TextStyle(
                                  color: AppColors.accentOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            aiReason!,
                            style: TextStyle(
                              color: AppColors.primaryText(context),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
