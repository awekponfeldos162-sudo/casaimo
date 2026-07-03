import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/listing/data/models/listing_model.dart';

class SearchListingCard extends StatefulWidget {
  final ListingModel listing;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const SearchListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
  });

  @override
  State<SearchListingCard> createState() => _SearchListingCardState();
}

class _SearchListingCardState extends State<SearchListingCard> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final images = l.mediaUrls.isNotEmpty ? l.mediaUrls : <String>[];
    final hasMany = images.length > 1;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image carousel ────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    // Images
                    images.isEmpty
                        ? Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.home_rounded, size: 60, color: AppColors.textHint),
                          )
                        : PageView.builder(
                            controller: _page,
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _index = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: images[i],
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                              errorWidget: (_, _, _) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.home_rounded, size: 48, color: AppColors.textHint),
                              ),
                            ),
                          ),

                    // Gradient bas
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badge prix (bas gauche)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6)],
                        ),
                        child: Text(
                          '${AppUtils.formatPrice(l.pricePerNight)} / nuit',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    // Compteur photos (bas droite)
                    if (hasMany)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_library_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${_index + 1}/${images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ),

                    // Bouton favori (haut droite)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: widget.onFavorite,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: widget.isFavorite ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    // Flèches navigation (si plusieurs images)
                    if (hasMany) ...[
                      if (_index > 0)
                        Positioned(
                          left: 8, top: 0, bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _page.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      if (_index < images.length - 1)
                        Positioned(
                          right: 8, top: 0, bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                    ],

                    // Points indicateurs (haut centre)
                    if (hasMany)
                      Positioned(
                        top: 10,
                        left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length.clamp(0, 6),
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: _index == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _index == i ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre
                  Text(
                    l.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Rating + avis
                  Row(children: [
                    _Stars(rating: l.avgRating),
                    const SizedBox(width: 5),
                    Text(
                      l.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${l.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // Type · Ville
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(l.type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    if (l.city.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          l.city,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 8),

                  // Specs rapides
                  Row(children: [
                    _SpecChip(icon: Icons.bed_rounded, label: '${l.bedrooms} ch.'),
                    const SizedBox(width: 8),
                    _SpecChip(icon: Icons.bathtub_rounded, label: '${l.bathrooms} sdb'),
                    const SizedBox(width: 8),
                    _SpecChip(icon: Icons.people_rounded, label: '${l.maxGuests} pers.'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded, size: 14, color: AppColors.star);
        } else if (i < rating && (rating - rating.floor()) >= 0.5) {
          return const Icon(Icons.star_half_rounded, size: 14, color: AppColors.star);
        }
        return const Icon(Icons.star_border_rounded, size: 14, color: AppColors.star);
      }),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.textSecondary),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
