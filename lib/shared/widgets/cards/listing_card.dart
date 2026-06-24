import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../features/listing/data/models/listing_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool isHorizontal;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal ? _buildHorizontal(context) : _buildVertical(context);
  }

  Widget _buildVertical(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSection(listing: listing, isFavorite: isFavorite, onFavorite: onFavorite),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _CardInfo(listing: listing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: listing.mainImage,
                width: 110, height: 110, fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(color: AppColors.surfaceVariant),
                errorWidget: (ctx, url, err) => Container(color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, color: AppColors.textHint)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(type: listing.type),
                    const SizedBox(height: 4),
                    Text(listing.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(child: Text(listing.city, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      _RatingChip(rating: listing.avgRating),
                    ]),
                  ],
                ),
              ),
            ),
            if (onFavorite != null)
              IconButton(icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? Colors.red : AppColors.textSecondary, size: 20), onPressed: onFavorite),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final ListingModel listing;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  const _ImageSection({required this.listing, required this.isFavorite, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedNetworkImage(
            imageUrl: listing.mainImage,
            height: 140, width: double.infinity, fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(height: 140, color: AppColors.surfaceVariant),
            errorWidget: (ctx, url, err) => Container(height: 140, color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, size: 40, color: AppColors.textHint)),
          ),
        ),
        Positioned(
          top: 10, left: 10,
          child: _TypeBadge(type: listing.type),
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: isFavorite ? Colors.red : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  final ListingModel listing;
  const _CardInfo({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(listing.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Row(children: [
        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Expanded(child: Text(listing.city, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        _RatingChip(rating: listing.avgRating),
      ]),
    ]);
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
      const SizedBox(width: 2),
      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }
}
