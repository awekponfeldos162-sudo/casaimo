import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/listing_card.dart';
import '../../../../shared/widgets/inputs/search_bar_widget.dart';
import '../../../../shared/widgets/layout/section_header.dart';
import '../../../../shared/widgets/layout/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final featuredAsync = ref.watch(featuredListingsProvider);
    final nearbyAsync = ref.watch(nearbyListingsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final featured = featuredAsync.valueOrNull ?? [];
    final nearby = nearbyAsync.valueOrNull ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            titleSpacing: 16,
            title: const Text(
              'CASAIMO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 3,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              if (user != null) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Location row
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Cotonou, Bénin', style: Theme.of(context).textTheme.bodySmall),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                ]),
                const SizedBox(height: 12),

                // Search bar
                SearchBarWidget(
                  hint: 'Rechercher un bien...',
                  readOnly: true,
                  onTap: () => context.go('/search'),
                  onFilter: () => context.go('/search'),
                ),
                const SizedBox(height: 20),

                // Categories
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final label = cat['label'] as String;
                      final isSelected = selectedCat == label;
                      return GestureDetector(
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state = label,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${cat['icon']} $label',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                SectionHeader(
                  title: 'Biens à proximité',
                  actionLabel: 'Voir plus',
                  onAction: () => context.go('/search'),
                ),
                const SizedBox(height: 14),
              ]),
            ),
          ),

          // Featured horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: featured.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) => const ListingCardSkeleton(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: featured.length,
                      itemBuilder: (_, i) {
                        final l = featured[i];
                        return ListingCard(
                          listing: l,
                          isFavorite:
                              ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                          onTap: () => context.push('/listing/${l.id}'),
                          onFavorite: () =>
                              ref.read(authProvider.notifier).toggleFavorite(l.id),
                        );
                      },
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: SectionHeader(
                title: 'Recommandés',
                actionLabel: 'Voir plus',
                onAction: () => context.go('/search'),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final l = nearby[i];
                  return ListingCard(
                    listing: l,
                    isHorizontal: true,
                    isFavorite:
                        ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                    onTap: () => context.push('/listing/${l.id}'),
                    onFavorite: () =>
                        ref.read(authProvider.notifier).toggleFavorite(l.id),
                  );
                },
                childCount: nearby.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
