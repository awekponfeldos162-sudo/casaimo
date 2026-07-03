import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/section_header.dart';
import '../../../../shared/widgets/layout/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/paginated_listings_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final featuredAsync = ref.watch(featuredListingsProvider);
    final nearbyAsync = ref.watch(nearbyListingsProvider);
    final villasAsync = ref.watch(villasProvider);
    final appsAsync = ref.watch(appsStudiosProvider);
    final paginated = ref.watch(paginatedListingsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final featured = featuredAsync.valueOrNull ?? [];
    final nearby = nearbyAsync.valueOrNull ?? [];
    final villas = villasAsync.valueOrNull ?? [];
    final apps = appsAsync.valueOrNull ?? [];
    final firstName = user?.name.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Header vert ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HomeHeader(
              firstName: firstName,
              avatarUrl: user?.avatarUrl ?? '',
              userName: user?.name ?? '',
              onNotif: () => context.push('/notifications'),
              onSearch: () => context.go('/search'),
              onFilter: () => context.go('/search'),
            ),
          ),

          // ── Catégories ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final label = cat['label'] as String;
                    final isSelected = selectedCat == label;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(selectedCategoryProvider.notifier).state =
                              label,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          '${cat['icon']} $label',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── En vedette ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: SectionHeader(
                title: 'En vedette',
                actionLabel: 'Voir tout',
                onAction: () => context.go('/search'),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: featured.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, _) => const ListingCardSkeleton(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      itemCount: featured.length,
                      itemBuilder: (_, i) => _FeaturedCard(
                        listing: featured[i],
                        isFavorite:
                            ref
                                .watch(authProvider)
                                ?.favoriteIds
                                .contains(featured[i].id) ??
                            false,
                        onTap: () => context.push('/listing/${featured[i].id}'),
                        onFavorite: () => ref
                            .read(authProvider.notifier)
                            .toggleFavorite(featured[i].id),
                      ),
                    ),
            ),
          ),

          // ── Recommandés ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SectionHeader(
                title: 'Recommandés',
                actionLabel: 'Voir tout',
                onAction: () => context.go('/search'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: nearby.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, _) => const ListingCardSkeleton(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      itemCount: nearby.length,
                      itemBuilder: (_, i) => _FeaturedCard(
                        listing: nearby[i],
                        isFavorite: ref.watch(authProvider)?.favoriteIds.contains(nearby[i].id) ?? false,
                        onTap: () => context.push('/listing/${nearby[i].id}'),
                        onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(nearby[i].id),
                      ),
                    ),
            ),
          ),

          // ── Villas & Maisons ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SectionHeader(
                title: 'Villas & Maisons',
                actionLabel: 'Voir tout',
                onAction: () {
                  ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(type: 'Villa'));
                  context.go('/search/results', extra: {'query': 'Villa'});
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: villas.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, _) => const ListingCardSkeleton(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      itemCount: villas.length,
                      itemBuilder: (_, i) => _FeaturedCard(
                        listing: villas[i],
                        isFavorite: ref.watch(authProvider)?.favoriteIds.contains(villas[i].id) ?? false,
                        onTap: () => context.push('/listing/${villas[i].id}'),
                        onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(villas[i].id),
                      ),
                    ),
            ),
          ),

          // ── Appartements & Studios ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SectionHeader(
                title: 'Appartements & Studios',
                actionLabel: 'Voir tout',
                onAction: () {
                  ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(type: 'Appartement'));
                  context.go('/search/results', extra: {'query': 'Appartement'});
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: apps.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, _) => const ListingCardSkeleton(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      itemCount: apps.length,
                      itemBuilder: (_, i) => _FeaturedCard(
                        listing: apps[i],
                        isFavorite: ref.watch(authProvider)?.favoriteIds.contains(apps[i].id) ?? false,
                        onTap: () => context.push('/listing/${apps[i].id}'),
                        onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(apps[i].id),
                      ),
                    ),
            ),
          ),

          // ── Tous les logements (paginés) ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SectionHeader(
                title: 'Tous les logements',
                actionLabel: 'Rechercher',
                onAction: () => context.go('/search'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final l = paginated.listings[i];
                  return _GridCard(
                    listing: l,
                    isFav: ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                    onTap: () => context.push('/listing/${l.id}'),
                    onFav: () => ref.read(authProvider.notifier).toggleFavorite(l.id),
                  );
                },
                childCount: paginated.listings.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: paginated.isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : paginated.hasMore
                        ? OutlinedButton.icon(
                            onPressed: () => ref.read(paginatedListingsProvider.notifier).loadMore(),
                            icon: const Icon(Icons.expand_more_rounded, size: 18),
                            label: const Text('Charger plus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                          )
                        : Text('Tout affiché · ${paginated.listings.length} logements',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final ListingModel listing;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onFav;
  const _GridCard({required this.listing, required this.isFav, required this.onTap, required this.onFav});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: listing.mainImage.isNotEmpty
                    ? CachedNetworkImage(imageUrl: listing.mainImage, width: double.infinity, fit: BoxFit.cover)
                    : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 36)),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onFav,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : AppColors.textSecondary, size: 16),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(listing.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(listing.city, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1),
              const SizedBox(height: 4),
              Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Header vert ──────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String firstName;
  final String avatarUrl;
  final String userName;
  final VoidCallback onNotif;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  const _HomeHeader({
    required this.firstName,
    required this.avatarUrl,
    required this.userName,
    required this.onNotif,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row : location | notif + avatar
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Cotonou, Bénin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNotif,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Greeting + titre
              if (firstName.isNotEmpty) ...[
                Text(
                  'Bonjour, $firstName 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
              ],
              const Text(
                'Trouvez votre\nlogement idéal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 18),

              // Search bar
              GestureDetector(
                onTap: onSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: _AnimatedSearchHint()),
                      GestureDetector(
                        onTap: onFilter,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grande carte En vedette ───────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final ListingModel listing;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _FeaturedCard({
    required this.listing,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 255,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              listing.mainImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.mainImage,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.home_rounded,
                        size: 50,
                        color: AppColors.textHint,
                      ),
                    ),

              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // Badge type haut gauche
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Bouton favori haut droite
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: isFavorite ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              // Info bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white60,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              listing.city,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.star,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${listing.avgRating.toStringAsFixed(1)} (${listing.reviewCount})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${AppUtils.formatPrice(listing.pricePerNight)}/nuit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barre de recherche animée ─────────────────────────────────────────────────

class _AnimatedSearchHint extends StatefulWidget {
  const _AnimatedSearchHint();

  @override
  State<_AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<_AnimatedSearchHint> {
  static const _hints = [
    'Trouvez rapidement les appartements...',
    'Budget 5000 - 9999999 FCFA...',
    'où que vous soyez vous pouvez trouver...',
    'Hôtel proche de vous ...',
    'Studio meublé à Cotonou...',
    'Maison à votre budget...',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _index = (_index + 1) % _hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        _hints[_index],
        key: ValueKey(_index),
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
