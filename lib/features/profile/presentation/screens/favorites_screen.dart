import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/cards/listing_card.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../../shared/widgets/layout/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes favoris')),
        body: EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Connectez-vous',
          subtitle: 'Enregistrez vos biens préférés pour les retrouver ici.',
          actionLabel: 'Se connecter',
          onAction: () => context.go('/login'),
        ),
      );
    }

    final listingsAsync = ref.watch(allListingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: listingsAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (all) {
          final favListings = all
              .where((l) => user.favoriteIds.contains(l.id))
              .toList();

          if (favListings.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Aucun favori',
              subtitle: "Appuyez sur le ❤️ sur un bien pour l'ajouter à vos favoris.",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favListings.length,
            itemBuilder: (_, i) {
              final l = favListings[i];
              return ListingCard(
                listing: l,
                isHorizontal: true,
                isFavorite: true,
                onTap: () => context.push('/listing/${l.id}'),
                onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(l.id),
              );
            },
          );
        },
      ),
    );
  }
}
