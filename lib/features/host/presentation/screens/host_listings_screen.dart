import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class HostListingsScreen extends ConsumerWidget {
  const HostListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final listingsAsync = ref.watch(hostListingsStreamProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.go('/host/listing/create'),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nouvelle annonce',
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyState(
              icon: Icons.home_work_rounded,
              title: 'Aucune annonce',
              subtitle: 'Créez votre première annonce pour commencer à recevoir des réservations.',
              actionLabel: 'Créer une annonce',
              onAction: () => context.go('/host/listing/create'),
            );
          }
          return Column(children: [
            // Summary bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primaryContainer,
              child: Row(children: [
                const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('${listings.length} annonce${listings.length > 1 ? 's' : ''} publiée${listings.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: listings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _HostListingCard(
                  listing: listings[index],
                  onTap: () => context.push('/listing/${listings[index].id}'),
                  onEdit: () => context.push('/host/listing/${listings[index].id}/edit'),
                  onDelete: () => _confirmDelete(context, ref, listings[index]),
                ),
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/host/listing/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouvelle annonce', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ListingModel listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'annonce ?'),
        content: Text('Voulez-vous vraiment supprimer "${listing.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(listingRepositoryProvider).delete(listing.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce supprimée'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _HostListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _HostListingCard({
    required this.listing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image + status
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: listing.mainImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.mainImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(height: 160, color: AppColors.surfaceVariant),
                      errorWidget: (ctx, url, err) => Container(height: 160, color: AppColors.surfaceVariant, child: const Icon(Icons.broken_image_rounded, color: AppColors.textHint, size: 32)),
                    )
                  : Container(height: 160, color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, size: 48, color: AppColors.textHint)),
            ),
            // Video badge
            if (listing.hasVideo)
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Vidéo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            // Status badge
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: listing.isPublished ? AppColors.success : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  listing.isPublished ? 'Publiée' : 'Brouillon',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Photo count
            if (listing.mediaUrls.length > 1)
              Positioned(
                bottom: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text('${listing.mediaUrls.length} photos', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
          ]),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text(listing.type, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                RatingBarIndicator(
                  rating: listing.avgRating,
                  itemCount: 5, itemSize: 14,
                  itemBuilder: (ctx, i) => const Icon(Icons.star_rounded, color: AppColors.star),
                ),
                const SizedBox(width: 4),
                Text('${listing.avgRating} (${listing.reviewCount})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 6),
              Text(listing.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(child: Text('${listing.city} · ${listing.address}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const Text('/nuit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
                if (listing.pricePerMonth > 0) ...[
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppUtils.formatPrice(listing.pricePerMonth), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const Text('/mois', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                ],
                const Spacer(),
                // Edit button
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Supprimer',
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
